# Unified search service that searches both Tools and Submissions
# Combines results from both sources and ranks them by relevance
class UnifiedSearchService
  # Search both tools and submissions
  #
  # @param query [String] Search query text
  # @param options [Hash] Search options
  #   - limit: [Integer] Maximum number of results per type (default: 10)
  #   - use_semantic: [Boolean] Whether to use semantic search for submissions (default: true)
  #   - use_fulltext: [Boolean] Whether to use full-text search (default: true)
  # @return [Hash] Hash with :tools and :submissions arrays
  def self.search(query, options = {})
    new(query, options).search
  end

  def initialize(query, options = {})
    @query = query.to_s.strip
    @limit = options[:limit] || 10
    @use_semantic = options.fetch(:use_semantic, true)
    @use_fulltext = options.fetch(:use_fulltext, true)
  end

  def search
    return { tools: [], submissions: [] } if @query.blank?

    # Search tools (simple ILIKE search for now - can be enhanced with pg_search later)
    tools = search_tools

    # Search submissions (using the existing SubmissionSearchService)
    submissions = search_submissions

    {
      tools: tools,
      submissions: submissions
    }
  end

  private

  # Search tools using simple ILIKE matching
  # Can be enhanced with pg_search later if needed
  def search_tools
    Tool.public_tools
        .left_joins(:tags)
        .where(
          "tools.tool_name ILIKE ? OR tools.tool_description ILIKE ? OR tags.tag_name ILIKE ?",
          "%#{@query}%", "%#{@query}%", "%#{@query}%"
        )
        .distinct
        .includes(:tags, :user_tools)
        .limit(@limit)
  rescue StandardError => e
    Rails.logger.error "Tool search error: #{e.message}"
    []
  end

  # Search submissions using the existing SubmissionSearchService
  def search_submissions
    SubmissionSearchService.search(
      @query,
      limit: @limit,
      status: :completed, # Only show completed submissions
      use_semantic: @use_semantic,
      use_fulltext: @use_fulltext
    )
  rescue StandardError => e
    Rails.logger.error "Submission search error: #{e.message}"
    []
  end
end
