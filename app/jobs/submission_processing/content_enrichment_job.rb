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
      tool = ::SubmissionTypeClassificationTool.new
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
      tool = ::SubmissionToolDetectionTool.new
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
    rescue StandardError => e
      Rails.logger.error "Tool detection error for submission #{submission.id}: #{e.message}"
    end

    # Generate and assign tags
    def generate_and_assign_tags(submission)
      tool = ::SubmissionTagGenerationTool.new
      result = tool.execute(
        title: submission.submission_name,
        description: submission.submission_description,
        author_note: submission.author_note,
        submission_type: submission.submission_type,
        url: submission.submission_url
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
          
          # Find or create tag (Tag model normalizes tag_name to lowercase automatically)
          tag = Tag.find_or_create_by!(
            tag_name: normalized_name,
            tag_type: tag_category
          ) do |t|
            t.tag_description = "Auto-generated from submission"
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
    rescue StandardError => e
      Rails.logger.error "Tag generation error for submission #{submission.id}: #{e.message}"
    end

    # Assign submission tags to all linked tools
    def assign_tags_to_linked_tools(submission)
      return if submission.tools.empty? || submission.tags.empty?

      assigned_count = 0
      submission.tools.each do |tool|
        submission.tags.each do |tag|
          unless tool.tags.include?(tag)
            tool.tags << tag
            assigned_count += 1
            Rails.logger.info "Assigned tag '#{tag.tag_name}' to tool #{tool.id} (#{tool.tool_name}) from submission #{submission.id}"
          end
        end
      end

      Rails.logger.info "Assigned #{assigned_count} tag(s) to #{submission.tools.count} tool(s) from submission #{submission.id}"
    rescue StandardError => e
      Rails.logger.error "Error assigning tags to tools for submission #{submission.id}: #{e.message}"
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
  end
end

