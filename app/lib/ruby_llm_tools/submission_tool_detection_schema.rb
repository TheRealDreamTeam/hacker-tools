# Schema for tool detection output
# Documentation: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
require 'ruby_llm/schema'

module RubyLlmTools
  class SubmissionToolDetectionSchema < RubyLLM::Schema
    array :tools do
      object do
        string :name, description: "The tool name"
        number :confidence, description: "Confidence score", minimum: 0, maximum: 1
        # Category is optional - omit from required array to make it optional
        string :category, 
          description: "Tool category (optional)",
          enum: %w[language framework library tool service platform other]
      end
    end
  end
end

