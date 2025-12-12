# Two-stage safety check for submissions
# Stage 1: Fast programmatic checks (domain blacklist, URL patterns)
# Stage 2: LLM-based content validation (only if Stage 1 passes)
module SubmissionProcessing
  class SafetyCheckJob < ApplicationJob
    queue_as :default

    # Public method that can be called directly (for orchestrator)
    def perform(submission_id)
      check_safety(submission_id)
    end

    private

    def check_safety(submission_id)
      submission = Submission.find(submission_id)
      
      # Skip if no URL (future text-only posts)
      return { safe: true } if submission.submission_url.blank?
      
      Rails.logger.info "Starting safety check for submission #{submission_id}"
      
      # Stage 1: Programmatic checks (fast, low cost)
      stage1_result = programmatic_check(submission)
      
      unless stage1_result[:safe]
        Rails.logger.warn "Submission #{submission_id} failed Stage 1 safety check: #{stage1_result[:reason]}"
        return stage1_result
      end
      
      # Stage 2: LLM-based validation (only if Stage 1 passes)
      stage2_result = llm_validation(submission)
      
      unless stage2_result[:safe]
        Rails.logger.warn "Submission #{submission_id} failed Stage 2 safety check: #{stage2_result[:reason]}"
        return stage2_result
      end
      
      Rails.logger.info "Submission #{submission_id} passed all safety checks"
      { safe: true }
    end

    # Stage 1: Fast programmatic checks
    def programmatic_check(submission)
      url = submission.submission_url
      
      # Check URL format
      begin
        uri = URI.parse(url)
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          return { safe: false, reason: "Invalid URL format", stage: 1 }
        end
      rescue URI::InvalidURIError
        return { safe: false, reason: "Invalid URL format", stage: 1 }
      end
      
      # Check domain blacklist
      domain = uri.host&.downcase
      if blacklisted_domains.any? { |blacklisted| domain&.include?(blacklisted) }
        return { safe: false, reason: "Domain is blacklisted", stage: 1 }
      end
      
      # Check for malicious URL patterns
      malicious_patterns = [
        /\.exe$/i,
        /\.zip$/i,
        /\.rar$/i,
        /javascript:/i,
        /data:text\/html/i,
        /\.onion$/i # Tor hidden services (can be legitimate, but often used for malicious content)
      ]
      
      if malicious_patterns.any? { |pattern| url.match?(pattern) }
        return { safe: false, reason: "URL contains suspicious patterns", stage: 1 }
      end
      
      # All checks passed
      { safe: true, stage: 1 }
    end

    # Stage 2: LLM-based content validation
    def llm_validation(submission)
      # Get scraped content if available
      content = build_content_for_validation(submission)
      
      return { safe: true, stage: 2 } if content.blank?
      
      # Use RubyLLM to validate content
      prompt = build_safety_validation_prompt(submission, content)
      
      begin
        chat = RubyLLM.chat(model: "gpt-4o-mini") # Use cheaper model for validation
        response = chat.ask(prompt)
        
        result = parse_safety_response(response.content)
        
        if result[:safe]
          { safe: true, stage: 2, confidence: result[:confidence] }
        else
          { safe: false, reason: result[:reason], stage: 2, confidence: result[:confidence] }
        end
      rescue StandardError => e
        Rails.logger.error "LLM safety validation error for submission #{submission.id}: #{e.message}"
        # If LLM fails, allow submission (fail open, but log the error)
        { safe: true, stage: 2, error: "LLM validation failed, allowing submission" }
      end
    end

    # Build content string for validation
    def build_content_for_validation(submission)
      parts = []
      
      # Use scraped metadata if available
      parts << submission.submission_name if submission.submission_name.present?
      parts << submission.submission_description if submission.submission_description.present?
      parts << submission.author_note if submission.author_note.present?
      
      # Add URL for context
      parts << "URL: #{submission.submission_url}" if submission.submission_url.present?
      
      parts.join("\n").strip
    end

    # Build prompt for LLM safety validation
    def build_safety_validation_prompt(submission, content)
      <<~PROMPT
        You are a content safety validator for a developer tool discovery platform.
        
        Analyze the following submission and determine if it's safe and appropriate:
        
        URL: #{submission.submission_url}
        Content:
        #{content}
        
        Check for:
        1. Pornography or explicit sexual content
        2. Violence, gore, or disturbing content
        3. Hate speech or discriminatory content
        4. Completely unrelated to software/tech/development (spam)
        5. Malicious content (phishing, malware, scams)
        6. Illegal content
        
        If the content is about software tools, frameworks, libraries, programming languages, 
        development practices, tech news, or related topics, it's SAFE.
        
        If the content is clearly inappropriate, malicious, or completely unrelated to tech, it's UNSAFE.
        
        Return your response as JSON:
        {
          "safe": true or false,
          "reason": "Brief explanation of your decision",
          "confidence": 0.0-1.0
        }
      PROMPT
    end

    # Parse LLM response
    def parse_safety_response(response_text)
      # Try to extract JSON from response
      json_match = response_text.match(/\{[\s\S]*\}/)
      return { safe: true, reason: "Could not parse response", confidence: 0.5 } unless json_match
      
      parsed = JSON.parse(json_match[0])
      {
        safe: parsed["safe"] == true,
        reason: parsed["reason"] || "No reason provided",
        confidence: parsed["confidence"]&.to_f || 0.5
      }
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse safety response: #{e.message}"
      { safe: true, reason: "Parse error", confidence: 0.5 }
    end

    # Domain blacklist (can be moved to config or database)
    def blacklisted_domains
      [
        # Add known malicious or inappropriate domains here
        # Example: "malicious-site.com"
      ]
    end
  end
end
