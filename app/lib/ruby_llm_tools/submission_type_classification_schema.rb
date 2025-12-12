# Schema for submission type classification output
# Documentation: https://rubyllm.com/chat/#getting-structured-output
# Uses ruby_llm-schema gem: https://github.com/danielfriis/ruby_llm-schema
require 'ruby_llm/schema'

class SubmissionTypeClassificationSchema < RubyLLM::Schema
  string :submission_type, 
    description: "The classified submission type",
    enum: %w[article guide documentation github_repo social_post code_snippet website video podcast other]
  number :confidence, 
    description: "Confidence score between 0 and 1",
    minimum: 0,
    maximum: 1
  string :reasoning, 
    description: "Brief explanation of the classification"
end

