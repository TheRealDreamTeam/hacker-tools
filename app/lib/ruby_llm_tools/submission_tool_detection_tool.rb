# RubyLLM Tool for detecting tools mentioned in submissions
# Documentation: https://rubyllm.com/tools/
class SubmissionToolDetectionTool < RubyLLM::Tool
  description "Detect software tools, frameworks, libraries, or technologies mentioned in a submission"
  
  param :title, type: "string", desc: "The submission title", required: false
  param :description, type: "string", desc: "The submission description", required: false
  param :author_note, type: "string", desc: "Optional author note from the user", required: false
  param :url, type: "string", desc: "The submission URL", required: false
  
  params do
    {
      type: "object",
      properties: {
        tools: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string", description: "The tool name" },
              confidence: { type: "number", minimum: 0, maximum: 1, description: "Confidence score" },
              category: { type: "string", enum: %w[language framework library tool service platform other], description: "Tool category" }
            },
            required: ["name", "confidence"]
          },
          description: "Array of detected tools"
        }
      },
      required: ["tools"]
    }
  end
  
  def execute(title: nil, description: nil, author_note: nil, url: nil)
    context = build_context(title, description, author_note, url)
    
    response = RubyLLM.chat(
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: "You are an expert at identifying software tools, frameworks, libraries, and technologies mentioned in content. " \
                   "Extract all relevant tools mentioned, including programming languages, frameworks, libraries, services, and platforms. " \
                   "Return your response as JSON with a tools array containing name, confidence, and category for each tool."
        },
        {
          role: "user",
          content: context
        }
      ],
      response_format: { type: "json_schema", json_schema: self.class.params_schema_definition.json_schema }
    )
    
    content = response.dig("choices", 0, "message", "content")
    result = JSON.parse(content)
    
    {
      tools: result["tools"] || []
    }
  rescue StandardError => e
    Rails.logger.error "Tool detection error: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    { tools: [] }
  end
  
  private
  
  def build_context(title, description, author_note, url)
    parts = []
    parts << "Title: #{title}" if title.present?
    parts << "Description: #{description}" if description.present?
    parts << "Author Note: #{author_note}" if author_note.present?
    parts << "URL: #{url}" if url.present?
    
    "Detect all software tools, frameworks, libraries, or technologies mentioned in this content:\n\n" \
    "#{parts.join("\n")}\n\n" \
    "Return a JSON array of detected tools with name, confidence, and category."
  end
end
