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
    if e.message.include?("Missing configuration for OpenAI")
      Rails.logger.error "Tool detection failed: OPENAI_API_KEY not configured. Set OPENAI_API_KEY in your .env file."
    else
      Rails.logger.error "Tool detection error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
    end
    { tools: [] }
  end
  
  private
  
  def build_context(title, description, author_note, url)
    parts = []
    parts << "Title: #{title}" if title.present?
    parts << "Description: #{description}" if description.present?
    parts << "Author Note: #{author_note}" if author_note.present?
    parts << "URL: #{url}" if url.present?
    
    # Extract domain from URL as a potential tool name hint
    domain_hint = ""
    if url.present?
      begin
        uri = URI.parse(url)
        domain = uri.host&.sub(/\Awww\./, "")&.split(".")&.first
        if domain.present? && domain.length > 2 && domain.length < 50
          # Only suggest domain if it looks like a project name (not generic domains)
          generic_domains = %w[github gitlab bitbucket npmjs pypi rubygems docker hub]
          unless generic_domains.include?(domain.downcase)
            domain_hint = "\n\nIMPORTANT: The URL domain suggests '#{domain}' might be a tool/project name. " \
                         "If this appears to be a software project, framework, or library, include it as a detected tool."
          end
        end
      rescue URI::InvalidURIError
        # Ignore invalid URLs
      end
    end
    
    "You are an expert at identifying software tools, frameworks, libraries, and technologies mentioned in content. " \
    "Extract all relevant tools mentioned, including programming languages, frameworks, libraries, services, and platforms.\n\n" \
    "PAY SPECIAL ATTENTION to the URL: domain names often indicate the name of a software project, framework, or tool. " \
    "For example, 'rubyllm.com' suggests 'rubyllm' is a tool, 'reactjs.org' suggests 'react' is a tool, etc.\n\n" \
    "IMPORTANT: Do NOT combine company names with product names unless they form a single, well-known tool name. " \
    "For example, if you see 'Disney' and 'Sora' mentioned together, and 'Sora' is OpenAI's product, " \
    "detect 'OpenAI' and 'Sora' separately, NOT 'Disney Sora'. " \
    "Only combine names if they represent a single, unified tool (e.g., 'Microsoft Azure', 'Google Cloud').\n\n" \
    "Content to analyze:\n#{parts.join("\n")}#{domain_hint}\n\n" \
    "Return a JSON array of detected tools with name, confidence, and category."
  end
end
