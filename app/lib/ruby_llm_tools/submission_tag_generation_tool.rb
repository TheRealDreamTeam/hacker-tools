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
    param :existing_tags, type: "array", desc: "Array of existing tags to prefer over creating new ones", required: false
    
    def execute(title: nil, description: nil, author_note: nil, submission_type: nil, url: nil, existing_tags: nil)
      context = build_context(title, description, author_note, submission_type, url, existing_tags)
      
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
    
    def build_context(title, description, author_note, submission_type, url, existing_tags)
      parts = []
      parts << "Submission Type: #{submission_type}" if submission_type.present?
      parts << "Title: #{title}" if title.present?
      parts << "Description: #{description}" if description.present?
      parts << "Author Note: #{author_note}" if author_note.present?
      parts << "URL: #{url}" if url.present?
      
      # Build existing tags section if provided
      existing_tags_section = ""
      if existing_tags.present? && existing_tags.any?
        # Group tags by type for better readability
        tags_by_type = existing_tags.group_by { |t| t[:type] || "Other" }
        existing_tags_list = tags_by_type.map do |type, tags|
          tag_names = tags.map { |t| t[:name] }.join(", ")
          "#{type}: #{tag_names}"
        end.join("\n")
        
        existing_tags_section = "\n\nEXISTING TAGS (CRITICAL - USE THESE WHEN POSSIBLE):\n" \
        "The following tags already exist in the system. You MUST prefer using these exact tag names " \
        "over creating new tags. Only create a new tag if there is no suitable existing tag that matches.\n" \
        "When an existing tag matches the concept you want to tag, use that exact tag name (case-sensitive).\n\n" \
        "#{existing_tags_list}\n\n" \
        "IMPORTANT: Before suggesting a new tag, check if any existing tag matches the concept. " \
        "Only create new tags when absolutely necessary and no existing tag is suitable."
      end
      
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
      "TAG DESCRIPTION RULES:\n" \
      "- For each tag, provide a brief, clear description (1 sentence, maximum 2 short sentences)\n" \
      "- The description MUST be 160 characters or less (strict limit)\n" \
      "- The description should explain what the tag represents and its relevance\n" \
      "- Be specific and informative (e.g., 'CSS is a stylesheet language used for describing the presentation of web documents')\n" \
      "- Avoid generic descriptions like 'A tag for X' or 'Related to X'\n" \
      "- Prioritize clarity and conciseness over length\n" \
      "#{existing_tags_section}" \
      "Content to tag:\n#{parts.join("\n")}\n\n" \
      "Return a JSON array of tags with name (following formatting rules), relevance score, category, and description."
    end
  end
end
