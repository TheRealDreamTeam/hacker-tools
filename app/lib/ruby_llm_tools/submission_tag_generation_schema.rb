# Schema for tag generation output
# Documentation: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
require 'ruby_llm/schema'

class SubmissionTagGenerationSchema < RubyLLM::Schema
  array :tags do
    object do
      string :name, description: "Tag name"
      number :relevance, description: "Relevance score", minimum: 0, maximum: 1
      string :category,
        description: "Tag category",
        enum: %w[category language framework library version platform other],
        required: false
    end
  end
end

