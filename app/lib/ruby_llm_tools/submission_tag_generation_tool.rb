# RubyLLM Tool for generating relevant tags for submissions
# Documentation: https://rubyllm.com/tools/
# Structured Output: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
class SubmissionTagGenerationTool < RubyLLM::Tool
  description "Generate relevant tags for a submission based on its content and type"
  
  param :title, type: "string", desc: "The submission title", required: false
  param :description, type: "string", desc: "The submission description", required: false
  param :author_note, type: "string", desc: "Optional author note", required: false
  param :submission_type, type: "string", desc: "The classified submission type", required: false
  param :url, type: "string", desc: "The submission URL", required: false
  
  # Define output schema using RubyLLM::Schema (recommended approach)
  params do
    RubyLLM::Schema.create do
      {
        tags: {
          type: :array,
          items: {
            type: :object,
            properties: {
              name: { type: :string, description: "Tag name" },
              relevance: { type: :number, minimum: 0, maximum: 1, description: "Relevance score" },
              category: { 
                type: :string, 
                enum: %w[category language framework library version platform other], 
                description: "Tag category" 
              }
            },
            required: [:name, :relevance]
          },
          description: "Array of generated tags (3-10 tags recommended)"
        }
      }
    end
  end
  
  def execute(title: nil, description: nil, author_note: nil, submission_type: nil, url: nil)
    context = build_context(title, description, author_note, submission_type, url)
    
    # Use gpt-4o or gpt-4.1-nano for structured output (not mini)
    chat = RubyLLM.chat(model: "gpt-4o")
    response = chat.ask(context)
    
    # RubyLLM::Schema ensures structured output
    result = JSON.parse(response.content)
    
    {
      tags: result["tags"] || []
    }
  rescue StandardError => e
    Rails.logger.error "Tag generation error: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    { tags: [] }
  end
  
  private
  
  def build_context(title, description, author_note, submission_type, url)
    parts = []
    parts << "Submission Type: #{submission_type}" if submission_type.present?
    parts << "Title: #{title}" if title.present?
    parts << "Description: #{description}" if description.present?
    parts << "Author Note: #{author_note}" if author_note.present?
    parts << "URL: #{url}" if url.present?
    
    "You are an expert at generating relevant tags for technical content. " \
    "Generate 3-10 relevant tags that accurately describe the submission. " \
    "Tags should be specific, relevant, and cover different aspects (technologies, topics, categories).\n\n" \
    "Content to tag:\n#{parts.join("\n")}\n\n" \
    "Return a JSON array of tags with name, relevance score, and category."
  end
end
