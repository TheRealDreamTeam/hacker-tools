namespace :tags do
  desc "Update tool_tags and submission_tags with correct tags from new tag structure"
  task update_associations: :environment do
    puts "== Updating Tag Associations =="
    
    # Mapping from old tag names (from seed data) to new tag slugs
    tag_mapping = {
      # Old category tags -> new tags
      "ruby" => "ruby",
      "rails" => "ruby-on-rails",
      "python" => "python",
      "javascript" => "javascript",
      "typescript" => "typescript",
      "react" => "react",
      "nextjs" => "nextjs",
      "vue" => "vue",
      "svelte" => "svelte",
      "go" => "go",
      "java" => "java",
      "c-sharp" => "c-sharp",
      "rust" => "rust",
      
      # Old category tags -> topic tags
      "frontend" => "frontend",
      "backend" => "backend",
      "devops" => "web-development", # Map to web-development topic
      "data" => "web-development", # Map to web-development topic
      "ai" => "web-development", # Map to web-development topic
      "llm" => "web-development", # Map to web-development topic
      "testing" => "testing",
      "productivity" => "web-development", # Map to web-development topic
      "observability" => "web-development", # Map to web-development topic
      "security" => "security",
      
      # Platform tags
      "postgres" => "postgresql",
      "kubernetes" => "kubernetes",
      "docker" => "docker",
      "redis" => "redis",
      "elasticsearch" => "mongodb", # Close match
      "github" => "github",
      "gitlab" => "gitlab"
    }
    
    # Find tags by slug (case-insensitive)
    def find_tag_by_slug(slug)
      Tag.find_by("LOWER(tag_slug) = ?", slug.downcase)
    end
    
    # Update tool tags
    puts "\n-> Updating tool tags..."
    tool_updates = {
      "Ruby on Rails" => ["ruby", "ruby-on-rails", "backend"],
      "Turbo" => ["react", "frontend"],
      "Stimulus" => ["react", "frontend"],
      "PostgreSQL" => ["postgresql", "backend"],
      "pgvector" => ["postgresql", "backend"],
      "Kubernetes" => ["kubernetes", "backend"],
      "Docker" => ["docker", "backend"],
      "GitHub Actions" => ["github", "backend"],
      "Prometheus" => ["backend"],
      "Grafana" => ["backend"],
      "LangChain" => ["python", "backend"],
      "OpenAI API" => ["backend"],
      "Pytest" => ["python", "testing"],
      "React" => ["react", "frontend"],
      "Vite" => ["react", "frontend"],
      "TypeScript" => ["typescript", "frontend"],
      "Next.js" => ["nextjs", "frontend"],
      "Tailwind CSS" => ["react", "frontend"],
      "Redis" => ["redis", "backend"],
      "Elasticsearch" => ["backend"],
      "Terraform" => ["backend"],
      "Ansible" => ["backend"],
      "Jenkins" => ["backend"],
      "Sentry" => ["backend"],
      "Datadog" => ["backend"],
      "Jupyter" => ["python", "backend"]
    }
    
    tool_count = 0
    Tool.find_each do |tool|
      tag_slugs = tool_updates[tool.tool_name] || []
      next if tag_slugs.empty?
      
      tags_to_add = tag_slugs.map { |slug| find_tag_by_slug(slug) }.compact
      
      if tags_to_add.any?
        tags_to_add.each do |tag|
          ToolTag.find_or_create_by(tool: tool, tag: tag)
        end
        tool_count += 1
        puts "  ✓ #{tool.tool_name}: #{tags_to_add.map(&:tag_name).join(', ')}"
      end
    end
    puts "  Updated #{tool_count} tools"
    
    # Update submission tags based on submission type and content
    puts "\n-> Updating submission tags..."
    submission_count = 0
    
    Submission.find_each do |submission|
      tags_to_add = []
      
      # Add content type tag based on submission_type
      content_type_tag = case submission.submission_type
      when "article"
        find_tag_by_slug("articles")
      when "guide"
        find_tag_by_slug("guides")
      when "documentation"
        find_tag_by_slug("documentation")
      when "github_repo"
        find_tag_by_slug("github-repos")
      when "video"
        find_tag_by_slug("videos")
      when "podcast"
        find_tag_by_slug("podcasts")
      else
        find_tag_by_slug("articles") # Default
      end
      tags_to_add << content_type_tag if content_type_tag
      
      # Add topic tags based on submission name/description
      submission_text = "#{submission.submission_name} #{submission.submission_description}".downcase
      
      # Programming languages
      tags_to_add << find_tag_by_slug("ruby") if submission_text.match?(/\bruby\b/i)
      tags_to_add << find_tag_by_slug("python") if submission_text.match?(/\bpython\b/i)
      tags_to_add << find_tag_by_slug("javascript") if submission_text.match?(/\bjavascript\b/i)
      tags_to_add << find_tag_by_slug("typescript") if submission_text.match?(/\btypescript\b/i)
      tags_to_add << find_tag_by_slug("react") if submission_text.match?(/\breact\b/i)
      tags_to_add << find_tag_by_slug("nextjs") if submission_text.match?(/\bnext\.?js\b/i)
      
      # Frameworks
      tags_to_add << find_tag_by_slug("ruby-on-rails") if submission_text.match?(/\brails\b/i)
      
      # Topics
      tags_to_add << find_tag_by_slug("backend") if submission_text.match?(/\b(backend|server|api|database|postgres|redis|kubernetes|docker)\b/i)
      tags_to_add << find_tag_by_slug("frontend") if submission_text.match?(/\b(frontend|react|vue|svelte|ui|client)\b/i)
      tags_to_add << find_tag_by_slug("testing") if submission_text.match?(/\b(test|pytest|testing|tdd)\b/i)
      tags_to_add << find_tag_by_slug("apis") if submission_text.match?(/\b(api|rest|graphql)\b/i)
      tags_to_add << find_tag_by_slug("deployment") if submission_text.match?(/\b(deploy|deployment|ci\/cd|pipeline)\b/i)
      tags_to_add << find_tag_by_slug("performance") if submission_text.match?(/\b(performance|optimization|speed)\b/i)
      
      # Databases
      tags_to_add << find_tag_by_slug("postgresql") if submission_text.match?(/\b(postgres|postgresql|pgvector)\b/i)
      tags_to_add << find_tag_by_slug("redis") if submission_text.match?(/\bredis\b/i)
      
      # Dev tools
      tags_to_add << find_tag_by_slug("docker") if submission_text.match?(/\bdocker\b/i)
      tags_to_add << find_tag_by_slug("kubernetes") if submission_text.match?(/\bkubernetes\b/i)
      tags_to_add << find_tag_by_slug("git") if submission_text.match?(/\bgit\b/i)
      
      # Remove duplicates and nil values
      tags_to_add = tags_to_add.compact.uniq
      
      if tags_to_add.any?
        tags_to_add.each do |tag|
          SubmissionTag.find_or_create_by(submission: submission, tag: tag)
        end
        submission_count += 1
        puts "  ✓ #{submission.submission_name}: #{tags_to_add.map(&:tag_name).join(', ')}"
      end
    end
    puts "  Updated #{submission_count} submissions"
    
    puts "\n== Done =="
    puts "Tool Tags: #{ToolTag.count}"
    puts "Submission Tags: #{SubmissionTag.count}"
  end
end

