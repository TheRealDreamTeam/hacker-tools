# Convenient rake tasks for generating embeddings for both tools and submissions
namespace :embedding do
  desc "Generate embeddings for all tools and submissions that don't have them"
  task generate: :environment do
    puts "=" * 80
    puts "Generating embeddings for tools and submissions..."
    puts "=" * 80
    puts
    
    # Generate embeddings for tools
    puts "📦 TOOLS"
    puts "-" * 80
    Rake::Task["tools:generate_embeddings"].invoke
    
    puts
    puts "=" * 80
    puts
    
    # Generate embeddings for submissions
    puts "📄 SUBMISSIONS"
    puts "-" * 80
    Rake::Task["submissions:generate_embeddings"].invoke
    
    puts
    puts "=" * 80
    puts "✅ Completed generating embeddings for all tools and submissions"
    puts "=" * 80
  end

  desc "Regenerate embeddings for all tools and submissions (even if they already have them)"
  task regenerate: :environment do
    puts "=" * 80
    puts "Regenerating embeddings for all tools and submissions..."
    puts "=" * 80
    puts
    
    # Regenerate embeddings for tools
    puts "📦 TOOLS"
    puts "-" * 80
    Rake::Task["tools:regenerate_embeddings"].invoke
    
    puts
    puts "=" * 80
    puts
    
    # Regenerate embeddings for submissions
    puts "📄 SUBMISSIONS"
    puts "-" * 80
    Rake::Task["submissions:regenerate_embeddings"].invoke
    
    puts
    puts "=" * 80
    puts "✅ Completed regenerating embeddings for all tools and submissions"
    puts "=" * 80
  end

end

# Top-level aliases for even shorter commands
desc "Generate embeddings for all tools and submissions (alias for embedding:generate)"
task embedding_gen: :environment do
  Rake::Task["embedding:generate"].invoke
end

desc "Regenerate embeddings for all tools and submissions (alias for embedding:regenerate)"
task embedding_regen: :environment do
  Rake::Task["embedding:regenerate"].invoke
end

