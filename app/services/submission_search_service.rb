# Service for searching submissions using hybrid approach:
# 1. PostgreSQL full-text search (pg_search) for keyword matching
# 2. Vector similarity search (embeddings) for semantic matching
# 3. Hybrid ranking to combine both results
#
# This provides both exact/partial keyword matches and semantic understanding
class SubmissionSearchService
  # Search submissions using hybrid approach
  #
  # @param query [String] Search query text
  # @param options [Hash] Search options
  #   - limit: [Integer] Maximum number of results (default: 20)
  #   - submission_type: [String, Symbol] Filter by submission type
  #   - status: [String, Symbol] Filter by status (default: completed)
  #   - use_semantic: [Boolean] Whether to use semantic search (default: true)
  #   - use_fulltext: [Boolean] Whether to use full-text search (default: true)
  # @return [Array<Submission>] Array of submissions ranked by relevance
  def self.search(query, options = {})
    new(query, options).search
  end

  def initialize(query, options = {})
    @query = query.to_s.strip
    @limit = options[:limit] || 20
    @submission_type = options[:submission_type]
    @status = options[:status] || :completed
    @use_semantic = options.fetch(:use_semantic, true)
    @use_fulltext = options.fetch(:use_fulltext, true)
  end

  def search
    return [] if @query.blank?

    # Start with base scope (only completed submissions by default)
    base_scope = Submission.where(status: Submission.statuses[@status])
    base_scope = base_scope.by_type(@submission_type) if @submission_type.present?

    # Get results from both search methods
    fulltext_results = @use_fulltext ? fulltext_search(base_scope) : []
    semantic_results = @use_semantic ? semantic_search(base_scope) : []

    # Combine and rank results
    combined_results = combine_results(fulltext_results, semantic_results)

    # Return top results
    combined_results.first(@limit)
  end

  private

  # Full-text search using pg_search
  # Returns submissions with relevance scores
  def fulltext_search(base_scope)
    return [] if @query.blank?

    # Use pg_search scope for full-text search
    # This uses PostgreSQL's full-text search with trigram for fuzzy matching
    results = base_scope.search_by_text(@query)
    
    # Return as array with relevance scores
    # pg_search adds a `pg_search_rank` attribute to each result
    results.to_a
  rescue StandardError => e
    Rails.logger.error "Full-text search error: #{e.message}"
    []
  end

  # Semantic search using vector embeddings
  # Returns submissions with similarity scores
  def semantic_search(base_scope)
    return [] if @query.blank?

    # Check if embedding column exists
    unless Submission.column_names.include?("embedding")
      Rails.logger.warn "Embedding column not available - skipping semantic search"
      return []
    end

    # Generate query embedding
    query_embedding = generate_query_embedding(@query)
    return [] if query_embedding.nil?

    # Find submissions with embeddings using cosine similarity
    # Use raw SQL for vector similarity search (pgvector)
    # Cosine distance: 1 - cosine_similarity (lower is more similar)
    # We want submissions where embedding <=> query_embedding < 0.8 (similarity > 0.2)
    sql = <<-SQL.squish
      SELECT submissions.*,
             (embedding <=> ?::vector) AS similarity_distance
      FROM submissions
      WHERE embedding IS NOT NULL
        AND status = ?
        #{@submission_type.present? ? "AND submission_type = ?" : ""}
      ORDER BY embedding <=> ?::vector
      LIMIT ?
    SQL

    params = [query_embedding, Submission.statuses[@status]]
    params << Submission.submission_types[@submission_type] if @submission_type.present?
    params << query_embedding
    params << @limit * 2 # Get more results for ranking

    results = Submission.find_by_sql([sql, *params])
    
    # Filter by similarity threshold (cosine distance < 0.8 means similarity > 0.2)
    # This filters out completely unrelated results
    results.select { |r| r.attributes["similarity_distance"].to_f < 0.8 }
  rescue StandardError => e
    Rails.logger.error "Semantic search error: #{e.message}"
    []
  end

  # Generate embedding for search query
  def generate_query_embedding(text)
    return nil if text.blank?

    # Use RubyLLM to generate embedding
    # Use text-embedding-3-small (1536 dimensions) to match submission embeddings
    embedding_result = RubyLLM.embed(text, model: "text-embedding-3-small")
    embedding_result.vectors.map(&:to_f)
  rescue StandardError => e
    Rails.logger.error "Query embedding generation error: #{e.message}"
    nil
  end

  # Combine full-text and semantic search results
  # Uses hybrid ranking: gives weight to both keyword matches and semantic similarity
  def combine_results(fulltext_results, semantic_results)
    # Create a hash to track submissions and their scores
    submission_scores = {}

    # Add full-text search results (weight: 0.6)
    # pg_search provides pg_search_rank (lower is better), so we normalize it
    if fulltext_results.any?
      max_rank = fulltext_results.map { |r| r.pg_search_rank || 1.0 }.max
      fulltext_results.each do |submission|
        normalized_rank = (submission.pg_search_rank || 1.0) / (max_rank + 0.1)
        score = 0.6 * (1.0 - normalized_rank) # Invert so higher score = better match
        submission_scores[submission.id] ||= { submission: submission, score: 0.0 }
        submission_scores[submission.id][:score] += score
      end
    end

    # Add semantic search results (weight: 0.4)
    # similarity_distance is cosine distance (lower is better)
    if semantic_results.any?
      max_distance = semantic_results.map { |r| r.attributes["similarity_distance"].to_f }.max
      semantic_results.each do |submission|
        distance = submission.attributes["similarity_distance"].to_f
        normalized_distance = max_distance > 0 ? distance / max_distance : 0.0
        score = 0.4 * (1.0 - normalized_distance) # Invert so higher score = better match
        submission_scores[submission.id] ||= { submission: submission, score: 0.0 }
        submission_scores[submission.id][:score] += score
      end
    end

    # Sort by combined score (descending) and return submissions
    submission_scores.values
                     .sort_by { |item| -item[:score] }
                     .map { |item| item[:submission] }
  end
end
