# RAG (Retrieval-Augmented Generation) service for enhanced search results
# Uses vector similarity to retrieve relevant submissions, then uses RubyLLM
# to generate contextual summaries and enhance search result descriptions
#
# This provides more intelligent search results by understanding context
# and relationships between submissions
require "json"

class SubmissionRagService
  # Enhance search results using RAG
  #
  # @param query [String] Original search query
  # @param submissions [Array<Submission>] Search results to enhance
  # @param options [Hash] Options
  #   - top_k: [Integer] Number of top submissions to use as context (default: 5)
  #   - enhance_all: [Boolean] Whether to enhance all results or just top ones (default: false)
  # @return [Array<Hash>] Array of enhanced results with summaries
  def self.enhance_results(query, submissions, options = {})
    new(query, submissions, options).enhance
  end

  def initialize(query, submissions, options = {})
    @query = query.to_s.strip
    @submissions = submissions.to_a
    @top_k = options[:top_k] || 5
    @enhance_all = options.fetch(:enhance_all, false)
  end

  def enhance
    return [] if @query.blank? || @submissions.empty?

    # Get top-K submissions for context
    context_submissions = @submissions.first(@top_k)

    # Generate context from top submissions
    context = build_context(context_submissions)

    # Enhance each submission (or just top ones)
    submissions_to_enhance = @enhance_all ? @submissions : context_submissions

    enhanced_results = submissions_to_enhance.map do |submission|
      enhance_submission(submission, context)
    end

    # Return enhanced results with original order preserved
    # For submissions not enhanced, return basic info
    @submissions.map do |submission|
      enhanced = enhanced_results.find { |r| r[:id] == submission.id }
      enhanced || {
        id: submission.id,
        submission: submission,
        enhanced_summary: nil,
        relevance_explanation: nil
      }
    end
  rescue StandardError => e
    Rails.logger.error "RAG enhancement error: #{e.message}"
    # Return unenhanced results on error
    @submissions.map do |submission|
      {
        id: submission.id,
        submission: submission,
        enhanced_summary: nil,
        relevance_explanation: nil
      }
    end
  end

  private

  # Build context from top submissions for LLM
  def build_context(submissions)
    return "" if submissions.empty?

    context_parts = submissions.map.with_index do |submission, index|
      # Format each submission as context
      parts = []
      parts << "Submission #{index + 1}:"
      parts << "Title: #{submission.submission_name}" if submission.submission_name.present?
      parts << "Description: #{submission.submission_description}" if submission.submission_description.present?
      parts << "Type: #{submission.submission_type}" if submission.submission_type.present?
      parts << "URL: #{submission.submission_url}" if submission.submission_url.present?
      
      # Add tags if available
      if submission.tags.any?
        tag_names = submission.tags.pluck(:tag_name).join(", ")
        parts << "Tags: #{tag_names}"
      end
      
      # Add tools if available
      if submission.tools.any?
        tool_names = submission.tools.pluck(:tool_name).join(", ")
        parts << "Tools: #{tool_names}"
      end
      
      parts.join("\n")
    end

    context_parts.join("\n\n")
  end

  # Enhance a single submission using RAG
  def enhance_submission(submission, context)
    # Build prompt for LLM
    prompt = build_enhancement_prompt(submission, context)

    # Use RubyLLM to generate enhanced summary
    chat = RubyLLM.chat(model: "gpt-4o-mini") # Use cheaper model for enhancement
    response = chat.ask(prompt)

    # Parse response (expecting JSON-like structure)
    # Response should contain: summary, relevance_explanation
    enhanced_data = parse_enhancement_response(response.content)

    {
      id: submission.id,
      submission: submission,
      enhanced_summary: enhanced_data[:summary] || submission.submission_description,
      relevance_explanation: enhanced_data[:relevance_explanation]
    }
  rescue StandardError => e
    Rails.logger.error "Error enhancing submission #{submission.id}: #{e.message}"
    # Return unenhanced result on error
    {
      id: submission.id,
      submission: submission,
      enhanced_summary: submission.submission_description,
      relevance_explanation: nil
    }
  end

  # Build prompt for LLM enhancement
  def build_enhancement_prompt(submission, context)
    <<~PROMPT
      You are helping enhance search results for a developer tool discovery platform.
      
      User Query: "#{@query}"
      
      Context (related submissions):
      #{context}
      
      Current Submission to Enhance:
      Title: #{submission.submission_name || "N/A"}
      Description: #{submission.submission_description || "N/A"}
      Type: #{submission.submission_type}
      URL: #{submission.submission_url || "N/A"}
      
      Please provide:
      1. A concise, enhanced summary (2-3 sentences) that explains why this submission is relevant to the query
      2. A brief explanation of how this submission relates to the query and the context provided
      
      Format your response as JSON:
      {
        "summary": "Enhanced summary here",
        "relevance_explanation": "Why this is relevant to the query"
      }
    PROMPT
  end

  # Parse LLM response (expecting JSON)
  def parse_enhancement_response(response_text)
    # Try to extract JSON from response
    # LLM might wrap JSON in markdown code blocks or add extra text
    json_match = response_text.match(/\{[\s\S]*\}/)
    return { summary: nil, relevance_explanation: nil } unless json_match

    parsed = JSON.parse(json_match[0])
    {
      summary: parsed["summary"],
      relevance_explanation: parsed["relevance_explanation"]
    }
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse enhancement response: #{e.message}"
    { summary: nil, relevance_explanation: nil }
  end
end
