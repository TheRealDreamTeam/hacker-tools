# RubyLLM Tool for discovering tool information (official website, GitHub repo, description)
# Documentation: https://rubyllm.com/tools/
# Structured Output: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
module RubyLlmTools
  class ToolDiscoveryTool < RubyLLM::Tool
    description "Discover official website, GitHub repository, and description for a software tool"
    
    param :tool_name, type: "string", desc: "The name of the tool to discover", required: true
    
    def execute(tool_name:)
      context = build_context(tool_name)
      
      # Use gpt-4o or gpt-4.1-nano for structured output (not mini)
      chat = RubyLLM.chat(model: "gpt-4o")
      
      # Use the schema for structured output - response.content is automatically a Hash
      response = chat.with_schema(ToolDiscoverySchema).ask(context)
      
      # RubyLLM::Schema ensures structured output, response.content is already a Hash
      {
        official_website: response.content["official_website"],
        github_repo: response.content["github_repo"],
        description: response.content["description"],
        confidence: response.content["confidence"]&.to_f,
        reasoning: response.content["reasoning"]
      }
    rescue StandardError => e
      if e.message.include?("Missing configuration for OpenAI")
        Rails.logger.error "Tool discovery failed: OPENAI_API_KEY not configured. Set OPENAI_API_KEY in your .env file."
      else
        Rails.logger.error "Tool discovery error: #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
      end
      {
        official_website: nil,
        github_repo: nil,
        description: nil,
        confidence: 0.0,
        reasoning: "Discovery failed due to error"
      }
    end
    
    private
    
    def build_context(tool_name)
      "You are an expert at finding information about software tools, frameworks, libraries, and technologies. " \
      "Given a tool name, discover its official website, GitHub repository (if applicable), and provide a brief description.\n\n" \
      "Tool name: #{tool_name}\n\n" \
      "Return the official website URL, GitHub repository URL (if it's an open-source project), " \
      "a brief description of what the tool is and what it does, and your confidence level."
    end
  end
end
