# Enriches submission with classification, tool detection, and tag generation using RubyLLM
module SubmissionProcessing
  class ContentEnrichmentJob < ApplicationJob
    queue_as :default

    # Load RubyLLM tools explicitly (Rails autoloading may not find them in background jobs)
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
      
      # Find or create tools and link the first high-confidence tool
      primary_tool = nil
      detected_tools.each do |tool_data|
        next unless tool_data["confidence"] && tool_data["confidence"] > 0.7
        
        tool_name = tool_data["name"]
        existing_tool = Tool.find_by("LOWER(tool_name) = ?", tool_name.downcase)
        
        if existing_tool
          primary_tool ||= existing_tool
          Rails.logger.info "Found existing tool: #{tool_name}"
        else
          # Create new tool if it doesn't exist
          new_tool = Tool.create!(
            tool_name: tool_name,
            tool_description: "Auto-detected from submission"
          )
          primary_tool ||= new_tool
          Rails.logger.info "Created new tool: #{tool_name}"
        end
        
        # Link submission to the first high-confidence tool
        break if primary_tool
      end
      
      # Link submission to primary tool
      if primary_tool && submission.tool_id.nil?
        submission.update!(tool_id: primary_tool.id)
        Rails.logger.info "Linked submission #{submission.id} to tool #{primary_tool.id}"
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

