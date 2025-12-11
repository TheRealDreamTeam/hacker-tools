# RubyLLM Tool for classifying submission types
# Documentation: https://rubyllm.com/tools/
# Structured Output: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
class SubmissionTypeClassificationTool < RubyLLM::Tool
  description "Classify the type of a submission (article, guide, documentation, github_repo, etc.) based on URL, title, and description"
  
  # Define parameters using param method
  param :url, type: "string", desc: "The submission URL", required: false
  param :title, type: "string", desc: "The submission title (extracted or provided)", required: false
  param :description, type: "string", desc: "The submission description (extracted or provided)", required: false
  param :author_note, type: "string", desc: "Optional author note from the user", required: false
  
  # Define output schema using RubyLLM::Schema
  # Documentation: https://rubyllm.com/chat/#using-rubyllm-schema-recommended
  def self.output_schema
    @output_schema ||= RubyLLM::Schema.create do
      {
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
      }
    end
  end
  
  # Execute the tool
  def execute(url: nil, title: nil, description: nil, author_note: nil)
    # Build context for the LLM
    context = build_context(url, title, description, author_note)
    
    # Use RubyLLM to classify with structured output
    # Use gpt-4o or gpt-4.1-nano for structured output (not mini)
    chat = RubyLLM.chat(model: "gpt-4o")
    
    # Use the schema for structured output
    response = chat.ask(
      context,
      response_format: {
        type: "json_schema",
        json_schema: self.class.output_schema.to_json_schema
      }
    )
    
    # Parse and return structured response
    # RubyLLM::Schema ensures structured output, so we can safely parse
    result = JSON.parse(response.content)
    
    {
      submission_type: result["submission_type"]&.to_sym,
      confidence: result["confidence"]&.to_f,
      reasoning: result["reasoning"]
    }
  rescue StandardError => e
    Rails.logger.error "Classification tool error: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    # Return default classification on error
    {
      submission_type: :article,
      confidence: 0.5,
      reasoning: "Classification failed, defaulting to article: #{e.message}"
    }
  end
  
  private
  
  def build_context(url, title, description, author_note)
    parts = []
    parts << "URL: #{url}" if url.present?
    parts << "Title: #{title}" if title.present?
    parts << "Description: #{description}" if description.present?
    parts << "Author Note: #{author_note}" if author_note.present?
    
    "You are an expert at classifying web content. Analyze the provided information and classify the submission type.\n\n" \
    "Content to classify:\n#{parts.join("\n")}\n\n" \
    "Return the classification with submission_type, confidence (0-1), and reasoning."
  end
end
