# Job for discovering and enriching tool information from the internet
# Runs automatically when a new tool is created
# TODO: Implement internet scraping to enrich tool show pages
#
# Planned functionality:
# - Search for tool's official website, GitHub repository, documentation
# - Extract tool description, logo/icon, metadata
# - Find related tools and technologies
# - Update tool with enriched data (tool_url, tool_description, icon, etc.)
#
# Potential data sources:
# - GitHub API (if tool_name matches a popular repository)
# - Web scraping (official website, documentation sites)
# - Package registries (npm, rubygems, pypi, etc.)
# - Wikipedia/other knowledge bases
class ToolDiscoveryJob < ApplicationJob
  queue_as :default

  # Retry on transient errors (network issues, rate limits, etc.)
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # Discard if tool no longer exists
  discard_on ActiveRecord::RecordNotFound

  def perform(tool_id)
    tool = Tool.find_by(id: tool_id)
    return unless tool

    Rails.logger.info "Starting tool discovery for tool #{tool_id}: #{tool.tool_name}"

    # TODO: Implement tool discovery logic
    # 1. Search for tool's official website/GitHub repo
    # 2. Extract metadata (description, logo, tags, etc.)
    # 3. Update tool with discovered information
    # 4. Handle errors gracefully (some tools may not have discoverable info)

    Rails.logger.info "Tool discovery completed for tool #{tool_id} (stub - not yet implemented)"
  rescue StandardError => e
    Rails.logger.error "Tool discovery error for tool #{tool_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    # Don't re-raise - tool discovery failures shouldn't break tool creation
  end
end

