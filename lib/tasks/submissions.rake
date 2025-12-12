# Rake tasks for submissions
namespace :submissions do
  desc "Generate embeddings for all submissions that don't have them"
  task generate_embeddings: :environment do
    puts "Generating embeddings for submissions without embeddings..."
    
    submissions_without_embeddings = Submission.where(embedding: nil)
    total = submissions_without_embeddings.count
    
    if total.zero?
      puts "All submissions already have embeddings!"
      next
    end
    
    puts "Found #{total} submissions without embeddings"
    
    submissions_without_embeddings.find_each.with_index do |submission, index|
      puts "[#{index + 1}/#{total}] Generating embedding for: #{submission.submission_name.presence || submission.submission_url}"
      SubmissionProcessing::EmbeddingGenerationJob.perform_now(submission.id)
    end
    
    puts "✅ Completed generating embeddings for #{total} submissions"
  end

  desc "Regenerate embeddings for all submissions (even if they already have them)"
  task regenerate_embeddings: :environment do
    puts "Regenerating embeddings for all submissions..."
    
    total = Submission.count
    
    if total.zero?
      puts "No submissions found!"
      next
    end
    
    puts "Found #{total} submissions"
    
    Submission.find_each.with_index do |submission, index|
      puts "[#{index + 1}/#{total}] Regenerating embedding for: #{submission.submission_name.presence || submission.submission_url}"
      SubmissionProcessing::EmbeddingGenerationJob.perform_now(submission.id)
    end
    
    puts "✅ Completed regenerating embeddings for #{total} submissions"
  end
end

