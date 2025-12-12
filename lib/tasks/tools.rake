# Rake tasks for tools
namespace :tools do
  desc "Generate embeddings for all tools that don't have them"
  task generate_embeddings: :environment do
    puts "Generating embeddings for tools without embeddings..."
    
    tools_without_embeddings = Tool.where(embedding: nil)
    total = tools_without_embeddings.count
    
    if total.zero?
      puts "All tools already have embeddings!"
      next
    end
    
    puts "Found #{total} tools without embeddings"
    
    tools_without_embeddings.find_each.with_index do |tool, index|
      puts "[#{index + 1}/#{total}] Generating embedding for: #{tool.tool_name}"
      ToolEmbeddingGenerationJob.perform_now(tool.id)
    end
    
    puts "✅ Completed generating embeddings for #{total} tools"
  end

  desc "Regenerate embeddings for all tools (even if they already have them)"
  task regenerate_embeddings: :environment do
    puts "Regenerating embeddings for all tools..."
    
    total = Tool.count
    
    if total.zero?
      puts "No tools found!"
      next
    end
    
    puts "Found #{total} tools"
    
    Tool.find_each.with_index do |tool, index|
      puts "[#{index + 1}/#{total}] Regenerating embedding for: #{tool.tool_name}"
      ToolEmbeddingGenerationJob.perform_now(tool.id)
    end
    
    puts "✅ Completed regenerating embeddings for #{total} tools"
  end
end
