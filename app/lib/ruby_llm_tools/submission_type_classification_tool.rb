# RubyLLM Tool for classifying submission types
# Documentation: https://rubyllm.com/tools/
class SubmissionTypeClassificationTool < RubyLLM::Tool
  # Define the tool's purpose and parameters
  description "Classify the type of a submission (article, guide, documentation, github_repo, etc.) based on URL, title, and description"
  
  # Define input parameters using RubyLLM::Schema
  parameter :url, type: :string, description: "The submission URL"
  parameter :title, type: :string, description: "The submission title (extracted or provided)"
  parameter :description, type: :string, description: "The submission description (extracted or provided)"
  parameter :author_note, type: :string, description: "Optional author note from the user"
  
  # Define output schema for structured response
  output_schema do
    {
      type: :object,
      properties: {
        submission_type: {
          type: :string,
          enum: %w[article guide documentation github_repo social_post code_snippet website video podcast other],
          description: "The classified submission type"
        },
        confidence: {
          type: :number,
          minimum: 0,
          maximum: 1,
          description: "Confidence score between 0 and 1"
        },
        reasoning: {
          type: :string,
          description: "Brief explanation of the classification"
        }
      },
      required: [:submission_type, :confidence]
    }
  end
  
  # Execute the tool
  def execute(url:, title: nil, description: nil, author_note: nil)
    # Build context for the LLM
    context = build_context(url, title, description, author_note)
    
    # Use RubyLLM to classify
    response = RubyLLM.chat(
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: "You are an expert at classifying web content. Analyze the provided information and classify the submission type."
        },
        {
          role: "user",
          content: context
        }
      ],
      response_format: { type: "json_schema", json_schema: output_schema }
    )
    
    # Parse and return structured response
    result = JSON.parse(response.dig("choices", 0, "message", "content"))
    
    {
      submission_type: result["submission_type"]&.to_sym,
      confidence: result["confidence"]&.to_f,
      reasoning: result["reasoning"]
    }
  rescue StandardError => e
    Rails.logger.error "Classification tool error: #{e.message}"
    # Return default classification on error
    {
      submission_type: :article,
      confidence: 0.5,
      reasoning: "Classification failed, defaulting to article"
    }
  end
  
  private
  
  def build_context(url, title, description, author_note)
    parts = []
    parts << "URL: #{url}" if url.present?
    parts << "Title: #{title}" if title.present?
    parts << "Description: #{description}" if description.present?
    parts << "Author Note: #{author_note}" if author_note.present?
    
    "Classify this submission:\n\n#{parts.join("\n")}\n\n" \
    "Return the classification as JSON with submission_type, confidence, and reasoning."
  end
end

