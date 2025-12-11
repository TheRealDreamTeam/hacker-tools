# RubyLLM Configuration
# Documentation: https://rubyllm.com/
# RubyLLM uses environment variables for configuration
# Set OPENAI_API_KEY in your environment or .env file

api_key = ENV["OPENAI_API_KEY"]

RubyLLM.configure do |config|
  config.openai_api_key = api_key
end

if api_key.present?
  Rails.logger.info "RubyLLM configured with OPENAI_API_KEY (length: #{api_key.length})"
else
  Rails.logger.warn "⚠️  OPENAI_API_KEY not set! Tag generation, tool detection, and classification will fail."
  Rails.logger.warn "   Set OPENAI_API_KEY in your .env file or environment to enable RubyLLM features."
end
