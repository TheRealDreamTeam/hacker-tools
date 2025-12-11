# RubyLLM Configuration
# Documentation: https://rubyllm.com/
# RubyLLM uses environment variables for configuration
# Set OPENAI_API_KEY in your environment or .env file

# The gem automatically reads OPENAI_API_KEY from ENV
# No explicit configuration block needed for basic usage
# For advanced configuration, see RubyLLM documentation

if ENV["OPENAI_API_KEY"].present?
  Rails.logger.info "RubyLLM configured with OPENAI_API_KEY"
else
  Rails.logger.warn "⚠️  OPENAI_API_KEY not set! Tag generation, tool detection, and classification will fail."
  Rails.logger.warn "   Set OPENAI_API_KEY in your .env file or environment to enable RubyLLM features."
end
