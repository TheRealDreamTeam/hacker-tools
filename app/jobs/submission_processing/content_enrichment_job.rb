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
      return if detected_tools.empty?
      
      # Store detected tools in metadata
      submission.metadata = submission.metadata.merge("detected_tools" => detected_tools)
      submission.save!
      
      # Filter high-confidence tools and find/create them
      high_confidence_tools = detected_tools.select { |t| t["confidence"] && t["confidence"] > 0.7 }
      return if high_confidence_tools.empty?
      
      # Find or create all high-confidence tools
      tool_records = []
      high_confidence_tools.each do |tool_data|
        tool_name = tool_data["name"]
        existing_tool = Tool.find_by("LOWER(tool_name) = ?", tool_name.downcase)
        
        if existing_tool
          tool_records << { tool: existing_tool, data: tool_data }
          Rails.logger.info "Found existing tool: #{tool_name}"
        else
          # Create new tool if it doesn't exist
          new_tool = Tool.create!(
            tool_name: tool_name,
            tool_description: "Auto-detected from submission"
          )
          tool_records << { tool: new_tool, data: tool_data }
          Rails.logger.info "Created new tool: #{tool_name}"
        end
      end
      
      # Select the best tool to link:
      # 1. Highest confidence
      # 2. If tie, prefer non-platform tools (platforms like GitHub are less specific)
      # 3. If still tie, prefer the first one
      primary_tool_record = tool_records.max_by do |record|
        data = record[:data]
        confidence = data["confidence"] || 0
        category = data["category"] || ""
        
        # Boost non-platform tools (platforms are usually hosting/services, less specific)
        confidence_boost = category == "platform" ? -0.1 : 0
        
        confidence + confidence_boost
      end
      
      # Link submission to the selected tool
      if primary_tool_record && submission.tool_id.nil?
        primary_tool = primary_tool_record[:tool]
        submission.update!(tool_id: primary_tool.id)
        Rails.logger.info "Linked submission #{submission.id} to tool #{primary_tool.id} (#{primary_tool.tool_name}, confidence: #{primary_tool_record[:data]["confidence"]})"
      end
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
      
      # Assign tags with relevance > 0.6
      assigned_count = 0
      generated_tags.each do |tag_data|
        next unless tag_data["relevance"] && tag_data["relevance"] > 0.6
        
        tag_name = tag_data["name"]
        tag_category = tag_data["category"] || "other"
        
        # Find or create tag
        tag = Tag.find_or_create_by!(
          tag_name: tag_name,
          tag_type: tag_category
        ) do |t|
          t.tag_description = "Auto-generated from submission"
        end
        
        # Associate tag with submission (if not already associated)
        unless submission.tags.include?(tag)
          submission.tags << tag
          assigned_count += 1
          Rails.logger.info "Assigned tag '#{tag_name}' to submission #{submission.id}"
        end
      end
      
      Rails.logger.info "Assigned #{assigned_count} tags to submission #{submission.id}"
    rescue StandardError => e
      Rails.logger.error "Tag generation error for submission #{submission.id}: #{e.message}"
    end
  end
end

