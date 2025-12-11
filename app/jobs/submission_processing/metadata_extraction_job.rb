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
        submission.update!(submission_name: title) if title.present?
        
        # Extract description
        description = extract_description(doc)
        submission.update!(submission_description: description) if description.present?
        
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
      return og_title if og_title.present?
      
      # Try Twitter card title
      twitter_title = doc.at_css('meta[name="twitter:title"]')&.[]('content')
      return twitter_title if twitter_title.present?
      
      # Fall back to page title
      doc.at_css('title')&.text&.strip
    end

    def extract_description(doc)
      # Try Open Graph description first
      og_desc = doc.at_css('meta[property="og:description"]')&.[]('content')
      return og_desc if og_desc.present?
      
      # Try Twitter card description
      twitter_desc = doc.at_css('meta[name="twitter:description"]')&.[]('content')
      return twitter_desc if twitter_desc.present?
      
      # Try meta description
      meta_desc = doc.at_css('meta[name="description"]')&.[]('content')
      return meta_desc if meta_desc.present?
      
      # Fall back to first paragraph
      doc.at_css('p')&.text&.strip&.truncate(500)
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
  end
end

