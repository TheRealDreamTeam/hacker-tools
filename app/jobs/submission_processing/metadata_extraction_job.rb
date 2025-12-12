# Extracts metadata from submission URL (title, description, images, etc.)
module SubmissionProcessing
  class MetadataExtractionJob < ApplicationJob
    queue_as :default

    # Public method that can be called directly (for orchestrator)
    def perform(submission_id)
      extract_metadata(submission_id)
    end

    private

    def extract_metadata(submission_id)
      submission = Submission.find(submission_id)
      
      # Skip if no URL
      return if submission.submission_url.blank?
      
      Rails.logger.info "Extracting metadata for submission #{submission_id}"
      
      begin
        # Fetch the URL content
        response = Faraday.get(submission.submission_url) do |req|
          req.headers["User-Agent"] = "HackerTools/1.0"
          req.options.timeout = 10
        end
        
        return unless response.success?
        
        # Parse HTML
        doc = Nokogiri::HTML(response.body)
        
        # Extract title
        title = extract_title(doc)
        if title.present? && title.length > 3 # Only update if we got a meaningful title
          submission.update!(submission_name: title)
          broadcast_title_update(submission)
        end
        
        # Extract description
        description = extract_description(doc)
        if description.present? && description.length > 10 # Only update if we got a meaningful description
          submission.update!(submission_description: description)
          broadcast_description_update(submission)
        end
        
        # Extract Open Graph image
        og_image = extract_og_image(doc)
        if og_image.present?
          submission.set_metadata_value(:og_image, og_image)
        end
        
        # Store raw HTML metadata
        submission.set_metadata_value(:extracted_at, Time.current.iso8601)
        
        Rails.logger.info "Metadata extraction completed for submission #{submission_id}"
      rescue Faraday::Error => e
        Rails.logger.warn "Failed to fetch URL for submission #{submission_id}: #{e.message}"
        # Don't fail the job - continue with what we have
      rescue StandardError => e
        Rails.logger.error "Metadata extraction error for submission #{submission_id}: #{e.message}"
        # Don't fail the job - continue with what we have
      end
    end

    private

    def extract_title(doc)
      # Try Open Graph title first
      og_title = doc.at_css('meta[property="og:title"]')&.[]('content')
      return og_title.strip if og_title.present? && og_title.strip.present?
      
      # Try Twitter card title
      twitter_title = doc.at_css('meta[name="twitter:title"]')&.[]('content')
      return twitter_title.strip if twitter_title.present? && twitter_title.strip.present?
      
      # Fall back to page title
      title = doc.at_css('title')&.text&.strip
      return title if title.present?
      
      nil
    end

    def extract_description(doc)
      # Try Open Graph description first
      og_desc = doc.at_css('meta[property="og:description"]')&.[]('content')
      return og_desc.strip if og_desc.present? && og_desc.strip.present?
      
      # Try Twitter card description
      twitter_desc = doc.at_css('meta[name="twitter:description"]')&.[]('content')
      return twitter_desc.strip if twitter_desc.present? && twitter_desc.strip.present?
      
      # Try meta description
      meta_desc = doc.at_css('meta[name="description"]')&.[]('content')
      return meta_desc.strip if meta_desc.present? && meta_desc.strip.present?
      
      # Fall back to first meaningful paragraph (skip empty/short ones)
      paragraphs = doc.css('p').map { |p| p.text.strip }.reject { |text| text.length < 50 }
      return paragraphs.first&.truncate(500) if paragraphs.any?
      
      nil
    end

    def extract_og_image(doc)
      # Try Open Graph image
      og_image = doc.at_css('meta[property="og:image"]')&.[]('content')
      return og_image if og_image.present?
      
      # Try Twitter card image
      twitter_image = doc.at_css('meta[name="twitter:image"]')&.[]('content')
      return twitter_image if twitter_image.present?
      
      nil
    end

    # Broadcast title update via Turbo Stream
    def broadcast_title_update(submission)
      Turbo::StreamsChannel.broadcast_update_to(
        "submission_#{submission.id}",
        target: "submission-title",
        html: submission.submission_name.presence || submission.submission_url
      )
      # Also update status badges (remove processing badge if completed)
      broadcast_status_badges_update(submission)
    rescue StandardError => e
      Rails.logger.warn "Failed to broadcast title update: #{e.message}"
    end

    # Broadcast description update via Turbo Stream
    def broadcast_description_update(submission)
      Turbo::StreamsChannel.broadcast_update_to(
        "submission_#{submission.id}",
        target: "submission-description",
        partial: "submissions/description_content",
        locals: { submission: submission }
      )
    rescue StandardError => e
      Rails.logger.warn "Failed to broadcast description update: #{e.message}"
    end

    # Broadcast status badges update
    def broadcast_status_badges_update(submission)
      Turbo::StreamsChannel.broadcast_update_to(
        "submission_#{submission.id}",
        target: "submission-status-badges",
        partial: "submissions/status_badges",
        locals: { submission: submission }
      )
    rescue StandardError => e
      Rails.logger.warn "Failed to broadcast status badges update: #{e.message}"
    end
  end
end

