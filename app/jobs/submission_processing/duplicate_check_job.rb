# Checks if a submission is a duplicate of an existing submission
# Returns hash with :duplicate (boolean), :duplicate_id (if duplicate), and :similar_submissions (array)
module SubmissionProcessing
  class DuplicateCheckJob < ApplicationJob
    queue_as :default

    # Public method that can be called directly (for orchestrator)
    def perform(submission_id)
      check_duplicate(submission_id)
    end

    private

    def check_duplicate(submission_id)
      submission = Submission.find(submission_id)
      
      # Skip if no URL (future text-only posts)
      return { duplicate: false, similar_submissions: [] } if submission.submission_url.blank?
      
      # Check for exact duplicate (same normalized_url from same user)
      # This is already handled by validation, but check for duplicates from other users
      existing = Submission.where(normalized_url: submission.normalized_url)
                           .where.not(id: submission.id)
                           .where.not(user_id: submission.user_id)
                           .first
      
      if existing
        Rails.logger.info "Found duplicate submission: #{submission.id} duplicates #{existing.id}"
        return { 
          duplicate: true, 
          duplicate_id: existing.id,
          similar_submissions: [existing]
        }
      end
      
      # Find similar submissions using fuzzy URL matching and semantic search
      similar_submissions = find_similar_submissions(submission)
      
      { 
        duplicate: false, 
        similar_submissions: similar_submissions
      }
    end

    # Find similar submissions using multiple methods
    def find_similar_submissions(submission)
      similar = []
      
      # Method 1: URL similarity using trigram (fuzzy matching)
      url_similar = find_url_similar_submissions(submission)
      similar.concat(url_similar)
      
      # Method 2: Semantic similarity using embeddings (if available)
      if submission.class.column_names.include?("embedding") && submission.embedding.present?
        semantic_similar = find_semantic_similar_submissions(submission)
        similar.concat(semantic_similar)
      end
      
      # Remove duplicates and limit results
      similar.uniq { |s| s.id }.first(5)
    end

    # Find submissions with similar URLs using PostgreSQL trigram
    def find_url_similar_submissions(submission)
      return [] if submission.normalized_url.blank?
      
      # Use trigram similarity to find URLs that are similar
      # Similarity threshold: 0.6 (60% similar)
      Submission.where.not(id: submission.id)
                .where.not(user_id: submission.user_id)
                .where("similarity(normalized_url, ?) > 0.6", submission.normalized_url)
                .order(Arel.sql("similarity(normalized_url, '#{submission.normalized_url}') DESC"))
                .limit(3)
    rescue StandardError => e
      Rails.logger.warn "URL similarity search failed: #{e.message}"
      []
    end

    # Find semantically similar submissions using embeddings
    def find_semantic_similar_submissions(submission)
      return [] unless submission.embedding.present?
      
      # Use vector similarity to find submissions with similar content
      # Cosine distance threshold: 0.7 (30% different = 70% similar)
      sql = <<-SQL.squish
        SELECT submissions.*,
               (embedding <=> ?::vector) AS similarity_distance
        FROM submissions
        WHERE embedding IS NOT NULL
          AND id != ?
          AND user_id != ?
          AND (embedding <=> ?::vector) < 0.7
        ORDER BY embedding <=> ?::vector
        LIMIT 3
      SQL
      
      Submission.find_by_sql([
        sql,
        submission.embedding,
        submission.id,
        submission.user_id,
        submission.embedding,
        submission.embedding
      ])
    rescue StandardError => e
      Rails.logger.warn "Semantic similarity search failed: #{e.message}"
      []
    end
  end
end

