# RubyLLM Configuration
# Documentation: https://rubyllm.com/
# RubyLLM uses environment variables for configuration
# Set OPENAI_API_KEY in your environment or .env file

# The gem automatically reads OPENAI_API_KEY from ENV
# No explicit configuration block needed for basic usage
# For advanced configuration, see RubyLLM documentation

Rails.logger.info "RubyLLM will use OPENAI_API_KEY from environment" if ENV["OPENAI_API_KEY"].present?
