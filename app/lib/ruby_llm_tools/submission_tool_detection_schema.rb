# Schema for tool detection output
# Documentation: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
require 'ruby_llm/schema'

class SubmissionToolDetectionSchema < RubyLLM::Schema
  array :tools do
    object do
      string :name, description: "The tool name"
      number :confidence, description: "Confidence score", minimum: 0, maximum: 1
      string :category, 
        description: "Tool category",
        enum: %w[language framework library tool service platform other],
        required: false
    end
  end
end

