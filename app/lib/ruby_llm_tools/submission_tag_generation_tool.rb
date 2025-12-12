# RubyLLM Tool for generating relevant tags for submissions
# Documentation: https://rubyllm.com/tools/
# Structured Output: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
module RubyLlmTools
  class SubmissionTagGenerationTool < RubyLLM::Tool
    description "Generate relevant tags for a submission based on its content and type"
    
    param :title, type: "string", desc: "The submission title", required: false
    param :description, type: "string", desc: "The submission description", required: false
    param :author_note, type: "string", desc: "Optional author note", required: false
    param :submission_type, type: "string", desc: "The classified submission type", required: false
    param :url, type: "string", desc: "The submission URL", required: false
    
    def execute(title: nil, description: nil, author_note: nil, submission_type: nil, url: nil)
      context = build_context(title, description, author_note, submission_type, url)
      
      # Use gpt-4o or gpt-4.1-nano for structured output (not mini)
      chat = RubyLLM.chat(model: "gpt-4o")
      
      # Use the schema for structured output - response.content is automatically a Hash
      response = chat.with_schema(SubmissionTagGenerationSchema).ask(context)
      
      # RubyLLM::Schema ensures structured output, response.content is already a Hash
      {
        tags: response.content["tags"] || []
      }
    rescue StandardError => e
      if e.message.include?("Missing configuration for OpenAI")
        Rails.logger.error "Tag generation failed: OPENAI_API_KEY not configured. Set OPENAI_API_KEY in your .env file."
      else
        Rails.logger.error "Tag generation error: #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
      end
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
      "TAG FORMATTING RULES (CRITICAL):\n" \
      "- All tags must be lowercase\n" \
      "- Prefer single words (e.g., 'react', 'javascript', 'svg')\n" \
      "- If multiple words are needed, use kebab-case with MAX 2 parts (e.g., 'web-development', 'ai-assisted')\n" \
      "- Do NOT create tags with more than 2 parts (e.g., avoid 'ai-assisted-coding' - split into 'ai', 'ai-assisted', 'coding')\n" \
      "- Examples of good tags: 'react', 'javascript', 'web-development', 'ai-assisted', 'machine-learning'\n" \
      "- Examples of bad tags: 'React', 'JavaScript', 'AI-Assisted-Coding', 'Machine Learning'\n\n" \
      "Content to tag:\n#{parts.join("\n")}\n\n" \
      "Return a JSON array of tags with name (following formatting rules), relevance score, and category."
    end
  end
end
