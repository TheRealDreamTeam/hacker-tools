# RubyLLM Tool for detecting tools mentioned in submissions
# Documentation: https://rubyllm.com/tools/
# Structured Output: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
class SubmissionToolDetectionTool < RubyLLM::Tool
  description "Detect software tools, frameworks, libraries, or technologies mentioned in a submission"
  
  param :title, type: "string", desc: "The submission title", required: false
  param :description, type: "string", desc: "The submission description", required: false
  param :author_note, type: "string", desc: "Optional author note from the user", required: false
  param :url, type: "string", desc: "The submission URL", required: false
  
  def execute(title: nil, description: nil, author_note: nil, url: nil)
    context = build_context(title, description, author_note, url)
    
    # Use gpt-4o or gpt-4.1-nano for structured output (not mini)
    chat = RubyLLM.chat(model: "gpt-4o")
    
    # Use the schema for structured output - response.content is automatically a Hash
    response = chat.with_schema(SubmissionToolDetectionSchema).ask(context)
    
    # RubyLLM::Schema ensures structured output, response.content is already a Hash
    {
      tools: response.content["tools"] || []
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
    
    "You are an expert at identifying software tools, frameworks, libraries, and technologies mentioned in content. " \
    "Extract all relevant tools mentioned, including programming languages, frameworks, libraries, services, and platforms.\n\n" \
    "Content to analyze:\n#{parts.join("\n")}\n\n" \
    "Return a JSON array of detected tools with name, confidence, and category."
  end
end
