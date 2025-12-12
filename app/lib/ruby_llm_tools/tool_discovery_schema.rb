# Schema for tool discovery output
# Documentation: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
require 'ruby_llm/schema'

class ToolDiscoverySchema < RubyLLM::Schema
  string :official_website, description: "The official website URL for the tool (if known)"
  string :github_repo, description: "The GitHub repository URL (if applicable, format: https://github.com/owner/repo)"
  string :description, description: "A brief description of what the tool is and what it does"
  number :confidence, 
    description: "Confidence score for the discovery", 
    minimum: 0, 
    maximum: 1
  string :reasoning, description: "Brief explanation of how the information was discovered"
end

