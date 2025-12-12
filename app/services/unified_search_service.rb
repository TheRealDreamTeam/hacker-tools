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

  # Search tools using hybrid approach: ILIKE matching + semantic search
  def search_tools
    # Get results from both search methods
    keyword_results = keyword_search_tools
    semantic_results = @use_semantic ? semantic_search_tools : []

    # Combine and rank results
    combined_results = combine_tool_results(keyword_results, semantic_results)

    # Return top results
    combined_results.first(@limit)
  rescue StandardError => e
    Rails.logger.error "Tool search error: #{e.message}"
    []
  end

  # Keyword search using ILIKE matching
  def keyword_search_tools
    return [] if @query.blank?

    Tool.public_tools
        .left_joins(:tags)
        .where(
          "tools.tool_name ILIKE ? OR tools.tool_description ILIKE ? OR tags.tag_name ILIKE ?",
          "%#{@query}%", "%#{@query}%", "%#{@query}%"
        )
        .distinct
        .includes(:tags, :user_tools)
        .limit(@limit * 2) # Get more results for ranking
  end

  # Semantic search using vector embeddings
  def semantic_search_tools
    return [] if @query.blank?

    # Check if embedding column exists
    unless Tool.column_names.include?("embedding")
      Rails.logger.warn "Embedding column not available for tools - skipping semantic search"
      return []
    end

    # Generate query embedding
    query_embedding = generate_query_embedding(@query)
    return [] if query_embedding.nil?

    # Format embedding array as PostgreSQL array literal string
    # pgvector requires the array to be formatted as '[0.1,0.2,0.3]' before casting to vector
    vector_string = "[#{query_embedding.join(',')}]"

    # Find tools with embeddings using cosine similarity
    # Use raw SQL for vector similarity search (pgvector)
    # Cosine distance: 1 - cosine_similarity (lower is more similar)
    # We want tools where embedding <=> query_embedding < 0.8 (similarity > 0.2)
    sql = <<-SQL.squish
      SELECT tools.*,
             (embedding <=> ?::vector) AS similarity_distance
      FROM tools
      WHERE embedding IS NOT NULL
        AND visibility = 0
      ORDER BY embedding <=> ?::vector
      LIMIT ?
    SQL

    params = [vector_string, vector_string, @limit * 2]

    results = Tool.find_by_sql([sql, *params])
    
    # Filter by similarity threshold (cosine distance < 0.8 means similarity > 0.2)
    # This filters out completely unrelated results
    results.select { |r| r.attributes["similarity_distance"].to_f < 0.8 }
  rescue StandardError => e
    Rails.logger.error "Semantic tool search error: #{e.message}"
    []
  end

  # Generate embedding for search query
  def generate_query_embedding(text)
    return nil if text.blank?

    # Use RubyLLM to generate embedding
    # Use text-embedding-3-small (1536 dimensions) to match tool embeddings
    embedding_result = RubyLLM.embed(text, model: "text-embedding-3-small")
    embedding_result.vectors.map(&:to_f)
  rescue StandardError => e
    Rails.logger.error "Query embedding generation error: #{e.message}"
    nil
  end

  # Combine keyword and semantic search results for tools
  def combine_tool_results(keyword_results, semantic_results)
    # Create a hash to track tools and their scores
    tool_scores = {}

    # Add keyword results with high weight (exact/partial matches are important)
    keyword_results.each do |tool|
      tool_scores[tool.id] ||= { tool: tool, score: 0.0 }
      tool_scores[tool.id][:score] += 1.0 # High weight for keyword matches
    end

    # Add semantic results with medium weight (semantic matches are valuable but less precise)
    semantic_results.each do |tool|
      similarity = 1.0 - tool.attributes["similarity_distance"].to_f # Convert distance to similarity
      tool_scores[tool.id] ||= { tool: tool, score: 0.0 }
      tool_scores[tool.id][:score] += similarity * 0.5 # Medium weight for semantic matches
    end

    # Sort by score (descending) and return tools
    tool_scores.values
               .sort_by { |entry| -entry[:score] }
               .map { |entry| entry[:tool] }
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
