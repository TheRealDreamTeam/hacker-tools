# Schema for tag generation output
# Documentation: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
require 'ruby_llm/schema'

module RubyLlmTools
  class SubmissionTagGenerationSchema < RubyLLM::Schema
    array :tags do
      object do
        string :name, description: "Tag name"
        number :relevance, description: "Relevance score", minimum: 0, maximum: 1
        # Category is optional - omit from required array to make it optional
        string :category,
          description: "Tag category (optional)",
          enum: %w[category language framework library version platform other]
      end
    end
  end
end

