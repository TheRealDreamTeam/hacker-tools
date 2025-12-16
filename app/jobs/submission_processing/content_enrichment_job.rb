# Enriches submission with classification, tool detection, and tag generation using RubyLLM
module SubmissionProcessing
  class ContentEnrichmentJob < ApplicationJob
    queue_as :default

    # Load RubyLLM tools and schemas explicitly (Rails autoloading may not find them in background jobs)
    Dir[Rails.root.join("app/lib/ruby_llm_tools/*.rb")].each { |f| require f }

    # Public method that can be called directly (for orchestrator)
    def perform(submission_id)
      enrich_content(submission_id)
    end

    private

    def enrich_content(submission_id)
      submission = Submission.find(submission_id)
      
      Rails.logger.info "Starting content enrichment for submission #{submission_id}"
      
      # Step 1: Classify submission type using RubyLLM
      classify_submission_type(submission)
      
      # Step 2: Detect tools mentioned in the submission
      detect_and_link_tools(submission)
      
      # Step 3: Generate and assign tags
      generate_and_assign_tags(submission)
      
      # Step 4: Assign submission tags to linked tools
      assign_tags_to_linked_tools(submission)
      
      Rails.logger.info "Content enrichment completed for submission #{submission_id}"
    end

    private

    # Classify submission type using RubyLLM
    def classify_submission_type(submission)
      return if submission.submission_url.blank?
      
      # Use RubyLLM classification tool (use :: prefix to look in root namespace)
      tool = RubyLlmTools::SubmissionTypeClassificationTool.new
      result = tool.execute(
        url: submission.submission_url,
        title: submission.submission_name,
        description: submission.submission_description,
        author_note: submission.author_note
      )
      
      if result[:submission_type] && result[:confidence] && result[:confidence] > 0.6
        submission.update!(submission_type: result[:submission_type])
        submission.set_metadata_value(:classification_confidence, result[:confidence])
        submission.set_metadata_value(:classification_reasoning, result[:reasoning])
        Rails.logger.info "Classified submission #{submission.id} as #{result[:submission_type]} (confidence: #{result[:confidence]})"
      else
        # Fallback to URL-based classification if LLM confidence is low
        classify_by_url_pattern(submission)
      end
    rescue StandardError => e
      Rails.logger.error "Classification error for submission #{submission.id}: #{e.message}"
      # Fallback to URL-based classification
      classify_by_url_pattern(submission)
    end

    # Fallback: Basic classification based on URL patterns
    def classify_by_url_pattern(submission)
      return if submission.submission_url.blank?
      
      url = submission.submission_url.downcase
      
      if url.include?("github.com")
        submission.update!(submission_type: :github_repo) unless submission.github_repo?
      elsif url.include?("docs.") || url.include?("/docs/") || url.include?("documentation")
        submission.update!(submission_type: :documentation) unless submission.documentation?
      elsif url.include?("guide") || url.include?("tutorial")
        submission.update!(submission_type: :guide) unless submission.guide?
      else
        # Default to article
        submission.update!(submission_type: :article) unless submission.article?
      end
    end

    # Detect tools and link submission to them
    def detect_and_link_tools(submission)
      tool = RubyLlmTools::SubmissionToolDetectionTool.new
      result = tool.execute(
        title: submission.submission_name,
        description: submission.submission_description,
        author_note: submission.author_note,
        url: submission.submission_url
      )
      
      detected_tools = result[:tools] || []
      
      # Fallback: Extract potential tool name from URL domain if not already detected
      # This catches cases like "rubyllm.com" where the domain name is the tool name
      if submission.submission_url.present?
        domain_tool = extract_tool_from_domain(submission.submission_url, detected_tools)
        detected_tools << domain_tool if domain_tool
      end
      
      return if detected_tools.empty?
      
      # Store detected tools in metadata
      submission.metadata = submission.metadata.merge("detected_tools" => detected_tools)
      submission.save!
      
      # Filter out hardware items (cables, physical devices, etc.)
      detected_tools = filter_hardware_items(detected_tools)
      
      # Filter out invalid tool combinations (e.g., "Disney Sora" when Sora is OpenAI's product)
      detected_tools = filter_invalid_tool_combinations(detected_tools)
      
      # Filter high-confidence tools and find/create them
      high_confidence_tools = detected_tools.select { |t| t["confidence"] && t["confidence"] > 0.7 }
      return if high_confidence_tools.empty?
      
      # Find or create all high-confidence tools and link them to the submission
      linked_tools = []
      high_confidence_tools.each do |tool_data|
        tool_name = tool_data["name"]
        existing_tool = Tool.find_by("LOWER(tool_name) = ?", tool_name.downcase)
        
        tool_record = if existing_tool
          Rails.logger.info "Found existing tool: #{tool_name}"
          existing_tool
        else
          # Create new tool if it doesn't exist
          new_tool = Tool.create!(
            tool_name: tool_name,
            tool_description: "Auto-detected from submission"
          )
          Rails.logger.info "Created new tool: #{tool_name}"
          new_tool
        end
        
        # Link submission to this tool (many-to-many relationship)
        unless submission.tools.include?(tool_record)
          submission.tools << tool_record
          linked_tools << tool_name
          Rails.logger.info "Linked submission #{submission.id} to tool #{tool_record.id} (#{tool_name}, confidence: #{tool_data["confidence"]})"
        end
      end
      
      Rails.logger.info "Linked submission #{submission.id} to #{linked_tools.count} tools: #{linked_tools.join(', ')}" if linked_tools.any?
      
      # Broadcast tools update if any tools were linked
      if linked_tools.any?
        broadcast_tools_update(submission)
      end
    rescue StandardError => e
      Rails.logger.error "Tool detection error for submission #{submission.id}: #{e.message}"
    end

    # Generate and assign tags
    def generate_and_assign_tags(submission)
      # Get existing tags to help LLM prefer them over creating new ones
      # Limit to most common/relevant tags to avoid overwhelming the context
      existing_tags = Tag.order(tag_type_id: :asc, tag_type: :asc, tag_name: :asc)
                        .limit(200)
                        .pluck(:tag_name, :tag_type)
                        .map { |name, type| { name: name, type: type } }
      
      tool = RubyLlmTools::SubmissionTagGenerationTool.new
      result = tool.execute(
        title: submission.submission_name,
        description: submission.submission_description,
        author_note: submission.author_note,
        submission_type: submission.submission_type,
        url: submission.submission_url,
        existing_tags: existing_tags
      )
      
      generated_tags = result[:tags] || []
      return if generated_tags.empty?
      
      # Store generated tags in metadata
      submission.metadata = submission.metadata.merge("generated_tags" => generated_tags)
      submission.save!
      
      # Normalize and assign tags with relevance > 0.6
      assigned_count = 0
      generated_tags.each do |tag_data|
        next unless tag_data["relevance"] && tag_data["relevance"] > 0.6
        
        original_tag_name = tag_data["name"]
        tag_category = tag_data["category"] || "other"
        
        # Normalize tag name(s) - may split into multiple tags
        normalized_tag_names = TagNormalizer.normalize(original_tag_name)
        
        normalized_tag_names.each do |normalized_name|
          # Normalize to lowercase (Tag model will also normalize, but do it here for consistency)
          normalized_name = normalized_name.downcase.strip
          next if normalized_name.blank?
          
          # Find existing tag by name (tag_name is unique, case-insensitive)
          # If tag exists, use it regardless of tag_type to avoid validation errors
          tag = Tag.find_by("LOWER(tag_name) = ?", normalized_name)
          
          # If tag doesn't exist, create it with the specified tag_type
          unless tag
            begin
              # Map old category names to new tag structure
              tag_type_mapping = map_category_to_tag_type(tag_category)
              
              # Use LLM-generated description if available, otherwise use a fallback
              tag_description = tag_data["description"].presence || "Auto-generated from submission"
              
              tag = Tag.create!(
                tag_name: normalized_name,
                tag_slug: normalized_name.parameterize,
                tag_type_id: tag_type_mapping[:tag_type_id],
                tag_type: tag_type_mapping[:tag_type],
                tag_type_slug: tag_type_mapping[:tag_type_slug],
                tag_description: tag_description,
                color: tag_type_mapping[:color] || "yellow",
                icon: tag_type_mapping[:icon] || "📝"
              )
            rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
              # If creation fails (e.g., race condition, unique constraint violation), try to find it again
              Rails.logger.warn "Tag creation failed for '#{normalized_name}': #{e.message}. Retrying find..."
              tag = Tag.find_by("LOWER(tag_name) = ?", normalized_name)
              unless tag
                Rails.logger.error "Could not find or create tag '#{normalized_name}' after retry"
                next
              end
            end
          end
          
          # Associate tag with submission (if not already associated)
          unless submission.tags.include?(tag)
            submission.tags << tag
            assigned_count += 1
            Rails.logger.info "Assigned tag '#{normalized_name}' to submission #{submission.id} (from '#{original_tag_name}')"
          end
        end
      end
      
      Rails.logger.info "Assigned #{assigned_count} tags to submission #{submission.id}"
      
      # Broadcast tags update if any tags were assigned
      if assigned_count > 0
        broadcast_tags_update(submission)
      end
    rescue StandardError => e
      Rails.logger.error "Tag generation error for submission #{submission.id}: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
    end

    # Assign submission tags to all linked tools
    # Only assigns tags that are appropriate for tools (e.g., programming languages, frameworks, platforms)
    # Excludes submission-specific tags (e.g., content-type tags like "games", "learning", "tutorial")
    def assign_tags_to_linked_tools(submission)
      return if submission.tools.empty? || submission.tags.empty?

      # Tag types that are appropriate for tools (describe the tool itself)
      # These tags describe technologies, platforms, frameworks, etc. that the tool represents
      tool_appropriate_tag_type_slugs = [
        "programming-language",
        "programming-language-version",
        "framework",
        "framework-version",
        "platform",
        "dev-tool",
        "database",
        "cloud-platform",
        "cloud-service",
        "topic",
        "task"
      ].freeze

      # Tag types that are submission-specific and should NOT be assigned to tools
      # These tags describe the submission's format/context (e.g., "games", "learning", "tutorial")
      submission_specific_tag_type_slugs = [
        "content-type",  # e.g., games, learning, tutorial, course, articles, videos
        "level"          # e.g., beginner, intermediate, advanced
      ].freeze

      # Specific tag names that describe submission format/context and should NOT be assigned to tools
      # These are tags that describe HOW the content is presented, not WHAT the tool is
      submission_format_tag_names = [
        "games", "learning", "tutorial", "course", "articles", "guides", 
        "documentation", "videos", "podcasts", "code snippets", "websites",
        "social posts", "discussions", "talks", "cheatsheets"
      ].freeze

      # Filter tags to only include those appropriate for tools
      tool_appropriate_tags = submission.tags.select do |tag|
        tag_type_slug = tag.tag_type_slug
        
        # If tag type is in the tool-appropriate list, check if it's not submission-specific
        if tool_appropriate_tag_type_slugs.include?(tag_type_slug)
          !submission_specific_tag_type_slugs.include?(tag_type_slug)
        # If tag type is content-type, only include if it's NOT a submission format tag
        elsif tag_type_slug == "content-type"
          !submission_format_tag_names.include?(tag.tag_name.downcase)
        else
          false
        end
      end

      return if tool_appropriate_tags.empty?

      assigned_count = 0
      submission.tools.each do |tool|
        tool_appropriate_tags.each do |tag|
          unless tool.tags.include?(tag)
            tool.tags << tag
            assigned_count += 1
            Rails.logger.info "Assigned tag '#{tag.tag_name}' (#{tag.tag_type_slug}) to tool #{tool.id} (#{tool.tool_name}) from submission #{submission.id}"
          end
        end
      end

      if assigned_count > 0
        Rails.logger.info "Assigned #{assigned_count} tool-appropriate tag(s) to #{submission.tools.count} tool(s) from submission #{submission.id}"
      else
        Rails.logger.debug "No tool-appropriate tags to assign from submission #{submission.id} (filtered out #{submission.tags.count - tool_appropriate_tags.count} submission-specific tags)"
      end
    rescue StandardError => e
      Rails.logger.error "Error assigning tags to tools for submission #{submission.id}: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
    end

    # Filter out hardware items (cables, physical devices, etc.) that are not software tools
    # This prevents items like "yaky" (a cable) or "USB-C" from being detected as software tools
    def filter_hardware_items(detected_tools)
      return detected_tools if detected_tools.empty?

      # Blacklist of known hardware items that should not be detected as software tools
      hardware_blacklist = %w[
        yaky usb-c usbc hdmi ethernet cable connector adapter charger battery
        phone smartphone tablet laptop computer monitor keyboard mouse
        chip processor cpu gpu memory ram storage ssd hdd
      ]

      # Hardware-related keywords that indicate a physical item, not software
      hardware_keywords = %w[
        cable connector port adapter charger battery power supply
        device hardware physical component chip processor
      ]

      filtered_tools = detected_tools.reject do |tool|
        tool_name = tool["name"].downcase.strip
        
        # Check against blacklist
        if hardware_blacklist.any? { |hw| tool_name == hw || tool_name.include?(hw) }
          Rails.logger.info "Filtering out hardware item: '#{tool["name"]}' (matches hardware blacklist)"
          next true
        end
        
        # Check category - if explicitly marked as hardware, exclude it
        if tool["category"] == "hardware" || tool["category"] == "device"
          Rails.logger.info "Filtering out hardware item: '#{tool["name"]}' (category: #{tool["category"]})"
          next true
        end
        
        # Check if tool name contains hardware keywords
        if hardware_keywords.any? { |keyword| tool_name.include?(keyword) }
          Rails.logger.info "Filtering out hardware item: '#{tool["name"]}' (contains hardware keyword)"
          next true
        end
        
        false # Keep this tool
      end
      
      filtered_tools
    end

    # Filter out invalid tool combinations like "Company Product" when the product belongs to another company
    # Example: "Disney Sora" should be filtered if "OpenAI" is detected and "Sora" is OpenAI's product
    def filter_invalid_tool_combinations(detected_tools)
      return detected_tools if detected_tools.empty?

      # Known product-company mappings (product name => company name)
      # This helps identify when a product name is incorrectly combined with the wrong company
      product_company_map = {
        "sora" => "openai",
        "gpt" => "openai",
        "dall-e" => "openai",
        "dalle" => "openai",
        "chatgpt" => "openai",
        "claude" => "anthropic",
        "gemini" => "google",
        "palm" => "google",
        "react" => "meta",
        "nextjs" => "vercel",
        "next.js" => "vercel",
        "rails" => "ruby",
        "django" => "python",
        "spring" => "java"
      }

      # Extract company/service names from detected tools (normalized to lowercase)
      company_names = detected_tools.map { |t| t["name"].downcase.strip }
      
      # Filter out tools that look like "Company Product" combinations
      filtered_tools = detected_tools.reject do |tool|
        tool_name = tool["name"].strip
        words = tool_name.split(/\s+/)
        
        # Only check multi-word tool names (e.g., "Disney Sora", "Microsoft GPT")
        next false if words.length < 2
        
        # Check each word to see if it's a known product
        words.each_with_index do |word, index|
          word_lower = word.downcase
          product_owner = product_company_map[word_lower]
          
          # If this word is a known product and its owner company is detected separately
          if product_owner && company_names.include?(product_owner)
            # Check if the first word is a different company (not the product owner)
            first_word = words.first.downcase
            if first_word != product_owner
              # This looks like an incorrect combination (e.g., "Disney Sora" when OpenAI is detected)
              Rails.logger.warn "Filtering out invalid tool combination: '#{tool_name}' - '#{word}' belongs to '#{product_owner}', not '#{words.first}'"
              return true # Reject this tool
            end
          end
        end
        
        false # Keep this tool
      end
      
      filtered_tools
    end

    # Extract potential tool name from URL domain as a fallback
    # This helps catch cases where the domain name is the tool name (e.g., rubyllm.com -> rubyllm)
    def extract_tool_from_domain(url, already_detected_tools)
      return nil if url.blank?

      begin
        uri = URI.parse(url)
        host = uri.host
        return nil if host.blank?

        # Remove www. prefix and extract the main domain part
        domain = host.sub(/\Awww\./, "")
        
        # Extract the first part before the TLD (e.g., "rubyllm" from "rubyllm.com")
        domain_parts = domain.split(".")
        return nil if domain_parts.empty?

        potential_tool_name = domain_parts.first
        return nil if potential_tool_name.blank?

        # Skip if it's too short or too long (likely not a tool name)
        return nil if potential_tool_name.length < 3 || potential_tool_name.length > 30

        # Skip generic domain names that are not tools
        generic_domains = %w[
          github gitlab bitbucket npmjs pypi rubygems docker hub
          com org net io co uk us de fr es it jp cn
          google microsoft apple amazon facebook twitter linkedin
          stackoverflow reddit medium devto hashnode
        ]
        return nil if generic_domains.include?(potential_tool_name.downcase)

        # Check if this tool name is already detected (case-insensitive)
        already_detected = already_detected_tools.any? do |t|
          t["name"]&.downcase == potential_tool_name.downcase
        end
        return nil if already_detected

        # Return as a potential tool with moderate confidence
        # The LLM will have higher confidence, but this is a reasonable fallback
        {
          "name" => potential_tool_name,
          "confidence" => 0.75, # Moderate confidence - domain suggests it's a tool
          "category" => "platform" # Default category, can be refined later
        }
      rescue URI::InvalidURIError
        nil
      end
    end

    # Broadcast tags update via Turbo Stream
    def broadcast_tags_update(submission)
      # Reload to get fresh tags
      submission.tags.reload
      Turbo::StreamsChannel.broadcast_update_to(
        "submission_#{submission.id}",
        target: "submission-tags",
        partial: "submissions/tags_section",
        locals: { submission: submission }
      )
    rescue StandardError => e
      Rails.logger.warn "Failed to broadcast tags update: #{e.message}"
    end

    # Broadcast tools update via Turbo Stream
    def broadcast_tools_update(submission)
      # Reload to get fresh tools
      submission.tools.reload
      Turbo::StreamsChannel.broadcast_update_to(
        "submission_#{submission.id}",
        target: "submission-tools-section",
        partial: "submissions/tools_section",
        locals: { submission: submission }
      )
    rescue StandardError => e
      Rails.logger.warn "Failed to broadcast tools update: #{e.message}"
    end

    # Map old category names to new tag structure
    # Maps legacy category values to new tag_type_id, tag_type, tag_type_slug, color, and icon
    def map_category_to_tag_type(category)
      mapping = {
        "category" => { tag_type_id: 2, tag_type: "Content Type", tag_type_slug: "content-type", color: "yellow", icon: "📝" },
        "language" => { tag_type_id: 3, tag_type: "Programming Language", tag_type_slug: "programming-language", color: "grey", icon: "⌨️" },
        "framework" => { tag_type_id: 5, tag_type: "Framework", tag_type_slug: "framework", color: "green", icon: "🧩" },
        "library" => { tag_type_id: 2, tag_type: "Content Type", tag_type_slug: "content-type", color: "yellow", icon: "📝" },
        "version" => { tag_type_id: 4, tag_type: "Language Version", tag_type_slug: "programming-language-version", color: "grey", icon: "🔢" },
        "platform" => { tag_type_id: 1, tag_type: "Platform", tag_type_slug: "platform", color: "black", icon: "🔗" },
        "other" => { tag_type_id: 2, tag_type: "Content Type", tag_type_slug: "content-type", color: "yellow", icon: "📝" }
      }
      
      # Default to "other" if category not found
      mapping[category.to_s.downcase] || mapping["other"]
    end
  end
end

