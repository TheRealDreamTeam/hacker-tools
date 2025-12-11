# RubyLLM Tool for generating relevant tags for submissions
# Documentation: https://rubyllm.com/tools/
class SubmissionTagGenerationTool < RubyLLM::Tool
  description "Generate relevant tags for a submission based on its content and type"
  
  parameter :title, type: :string, description: "The submission title"
  parameter :description, type: :string, description: "The submission description"
  parameter :author_note, type: :string, description: "Optional author note"
  parameter :submission_type, type: :string, description: "The classified submission type"
  parameter :url, type: :string, description: "The submission URL"
  
  output_schema do
    {
      type: :object,
      properties: {
        tags: {
          type: :array,
          items: {
            type: :object,
            properties: {
              name: { type: :string, description: "Tag name" },
              relevance: { type: :number, minimum: 0, maximum: 1, description: "Relevance score" },
              category: { type: :string, enum: %w[category language framework library version platform other], description: "Tag category" }
            },
            required: [:name, :relevance]
          },
          description: "Array of generated tags (3-10 tags recommended)"
        }
      },
      required: [:tags]
    }
  end
  
  def execute(title: nil, description: nil, author_note: nil, submission_type: nil, url: nil)
    context = build_context(title, description, author_note, submission_type, url)
    
    response = RubyLLM.chat(
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: "You are an expert at generating relevant tags for technical content. " \
                   "Generate 3-10 relevant tags that accurately describe the submission. " \
                   "Tags should be specific, relevant, and cover different aspects (technologies, topics, categories)."
        },
        {
          role: "user",
          content: context
        }
      ],
      response_format: { type: "json_schema", json_schema: output_schema }
    )
    
    result = JSON.parse(response.dig("choices", 0, "message", "content"))
    
    {
      tags: result["tags"] || []
    }
  rescue StandardError => e
    Rails.logger.error "Tag generation error: #{e.message}"
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
    
    "Generate relevant tags for this submission:\n\n#{parts.join("\n")}\n\n" \
    "Return a JSON array of tags with name, relevance score, and category."
  end
end

