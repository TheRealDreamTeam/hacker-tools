# RubyLLM Configuration
# Documentation: https://rubyllm.com/

RubyLLM.configure do |config|
  # Use OpenAI as the default provider
  config.provider = :openai
  
  # Set API key from environment variable
  config.api_key = ENV.fetch("OPENAI_API_KEY", nil)
  
  # Default model for structured output (classification, tool detection, etc.)
  config.default_model = "gpt-4o-mini"
  
  # Model for complex tasks requiring better reasoning
  config.complex_model = "gpt-4o"
  
  # Error handling
  config.raise_on_error = false # Don't raise exceptions, return nil instead
  
  Rails.logger.info "RubyLLM configured with provider: #{config.provider}"
end

