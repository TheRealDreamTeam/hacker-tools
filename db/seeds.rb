# frozen_string_literal: true

# Comprehensive seed data that covers the current domain model:
# - Users (including a soft-deleted user to exercise reuse rules)
# - Tags (with parent/child relationships and typed enums)
# - Community-owned Tools (no owner column) with tags
# - Submissions (user owned) linked to tools, tags, lists, follows, and upvotes
# - Lists that contain both tools and submissions
# - Interactions: upvotes/favorites, follows, comments, comment upvotes
#
# Usage:
#   bin/rails db:seed                    # Idempotent, adds/updates records
#   SEED_PURGE=true bin/rails db:seed    # Danger: wipes domain tables first
#
# Notes:
# - We temporarily disable the Tool discovery callback to avoid enqueuing jobs
#   during seeding; it is re-enabled afterward.
# - All lookups use find_or_initialize_by / find_or_create_by to stay idempotent.

require "active_support/core_ext/integer/time"

puts "== Seeding database =="

SEED_PURGE = ENV["SEED_PURGE"] == "true"
DEFAULT_PASSWORD = ENV.fetch("SEED_PASSWORD", "password123")

def log_step(message)
  puts "-> #{message}"
end

def attach_tags(record, tag_keys, tags_lookup)
  Array(tag_keys).compact.each do |tag_key|
    tag = tags_lookup[tag_key]
    next unless tag

    record.tags << tag unless record.tags.include?(tag)
  end
end

ActiveRecord::Base.transaction do
  if SEED_PURGE
    log_step "Purging existing data (SEED_PURGE=true)"
    [
      CommentUpvote,
      Comment,
      ListSubmission,
      ListTool,
      SubmissionTag,
      SubmissionTool,
      ToolTag,
      Follow,
      UserSubmission,
      UserTool,
      List,
      Submission,
      Tool,
      Tag,
      User
    ].each(&:delete_all)
  end

  # Users
  log_step "Creating users"
  users = {}
  user_defs = [
    { key: :alice, email: "alice@example.com", username: "alice_dev", bio: "Full-stack dev shipping dashboards with Hotwire and Rails." },
    { key: :bob, email: "bob@example.com", username: "bob_ops", bio: "Infra/DevOps. Kubernetes and Terraform all day." },
    { key: :charlie, email: "charlie@example.com", username: "charlie_frontend", bio: "Frontend lead focused on DX and performance." },
    { key: :diana, email: "diana@example.com", username: "diana_data", bio: "Data/ML engineer building evals and pipelines." },
    { key: :eve, email: "eve@example.com", username: "eve_security", bio: "Security engineer building safer CI/CD." },
    { key: :frank, email: "frank@example.com", username: "frank_product", bio: "PM curating tools for the team." },
    { key: :grace, email: "grace@example.com", username: "grace_mobile", bio: "Mobile developer working on React Native and Flutter apps." },
    { key: :henry, email: "henry@example.com", username: "henry_backend", bio: "Backend engineer specializing in microservices and APIs." },
    { key: :ivy, email: "ivy@example.com", username: "ivy_design", bio: "Design engineer bridging UI/UX and frontend development." },
    { key: :jack, email: "jack@example.com", username: "jack_qa", bio: "QA engineer focused on automation and test infrastructure." },
    { key: :kate, email: "kate@example.com", username: "kate_ml", bio: "ML engineer building recommendation systems and NLP models." },
    { key: :liam, email: "liam@example.com", username: "liam_sre", bio: "SRE managing production systems and incident response." },
    { key: :mia, email: "mia@example.com", username: "mia_architect", bio: "Solutions architect designing scalable distributed systems." }
  ]

  user_defs.each do |attrs|
    user = User.find_or_initialize_by(email: attrs[:email])
    user.username = attrs[:username]
    user.user_bio = attrs[:bio]
    user.password = DEFAULT_PASSWORD if user.new_record?
    user.user_status = :active
    user.save!
    users[attrs[:key]] = user
  end

  # Soft-deleted user to validate historical associations remain intact
  ghost = User.find_or_initialize_by(email: "ghost@example.com")
  ghost.username = "ghost_user"
  ghost.user_bio = "Former user kept for historical associations."
  ghost.password = DEFAULT_PASSWORD if ghost.new_record?
  ghost.user_status = :active
  ghost.save!
  ghost.soft_delete! unless ghost.deleted?
  users[:ghost] = ghost

  # Tags (comprehensive tag system with new structure)
  log_step "Creating tags"
  tags = {}
  tags_by_id = {}

  # Comprehensive tag definitions with new structure
  tag_defs = [
    # Content Type tags (tag_type_id: 2)
    { id: 1, name: "Articles", slug: "articles", description: "Blog posts and written content", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "📝" },
    { id: 2, name: "Guides", slug: "guides", description: "Step-by-step tutorials", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "📘" },
    { id: 3, name: "Documentation", slug: "documentation", description: "Official documentation pages", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "📖" },
    { id: 4, name: "GitHub Repos", slug: "github-repos", description: "Code repositories and projects", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "💻" },
    { id: 5, name: "Videos", slug: "videos", description: "Video-based content", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "🎥" },
    { id: 6, name: "Podcasts", slug: "podcasts", description: "Audio-based discussions", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "🎙️" },
    { id: 7, name: "Code Snippets", slug: "code-snippets", description: "Small reusable code examples", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "💾" },
    { id: 8, name: "Websites", slug: "websites", description: "Product or company websites", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "🌍" },
    { id: 9, name: "Social Posts", slug: "social-posts", description: "Short-form social content", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "🐦" },
    { id: 10, name: "Discussions", slug: "discussions", description: "Community discussions", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "💬" },
    { id: 11, name: "Courses", slug: "courses", description: "Structured learning content", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "🎓" },
    { id: 12, name: "Talks", slug: "talks", description: "Conference talks", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "🎤" },
    { id: 13, name: "Cheatsheets", slug: "cheatsheets", description: "Quick reference material", type_id: 2, type: "Content Type", type_slug: "content-type", parent_id: nil, color: "yellow", icon: "🧾" },
    # Platform tags (tag_type_id: 1)
    { id: 20, name: "YouTube", slug: "youtube", description: "Video hosting platform", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 21, name: "GitHub", slug: "github", description: "Code hosting platform", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 22, name: "MDN", slug: "mdn", description: "Web standards documentation", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 23, name: "Dev.to", slug: "devto", description: "Developer blogging platform", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 24, name: "Stack Overflow", slug: "stack-overflow", description: "Developer Q&A platform", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 25, name: "GitLab", slug: "gitlab", description: "Code hosting platform", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 26, name: "Bitbucket", slug: "bitbucket", description: "Code hosting platform", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 27, name: "Hacker News", slug: "hacker-news", description: "Tech news and discussions", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 28, name: "Reddit", slug: "reddit", description: "Community discussions", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 29, name: "LinkedIn", slug: "linkedin", description: "Professional social platform", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 30, name: "X", slug: "x", description: "Short-form social platform", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 31, name: "npm", slug: "npm", description: "JavaScript package registry", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 32, name: "PyPI", slug: "pypi", description: "Python package index", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 33, name: "RubyGems", slug: "rubygems", description: "Ruby package registry", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    { id: 34, name: "Docker Hub", slug: "docker-hub", description: "Container image registry", type_id: 1, type: "Platform", type_slug: "platform", parent_id: nil, color: "black", icon: "🔗" },
    # Programming Language tags (tag_type_id: 3)
    { id: 100, name: "Ruby", slug: "ruby", description: "Ruby programming language", type_id: 3, type: "Programming Language", type_slug: "programming-language", parent_id: nil, color: "grey", icon: "⌨️", keys: %i[ruby] },
    { id: 101, name: "Ruby 3.3", slug: "ruby-3-3", description: "Ruby version 3.3", type_id: 4, type: "Language Version", type_slug: "programming-language-version", parent_id: 100, color: "grey", icon: "🔢" },
    { id: 102, name: "Ruby 3.2", slug: "ruby-3-2", description: "Ruby version 3.2", type_id: 4, type: "Language Version", type_slug: "programming-language-version", parent_id: 100, color: "grey", icon: "🔢" },
    { id: 110, name: "Python", slug: "python", description: "Python programming language", type_id: 3, type: "Programming Language", type_slug: "programming-language", parent_id: nil, color: "grey", icon: "⌨️", keys: %i[python] },
    { id: 111, name: "Python 3.12", slug: "python-3-12", description: "Python version 3.12", type_id: 4, type: "Language Version", type_slug: "programming-language-version", parent_id: 110, color: "grey", icon: "🔢" },
    { id: 112, name: "Python 3.11", slug: "python-3-11", description: "Python version 3.11", type_id: 4, type: "Language Version", type_slug: "programming-language-version", parent_id: 110, color: "grey", icon: "🔢" },
    { id: 120, name: "JavaScript", slug: "javascript", description: "JavaScript programming language", type_id: 3, type: "Programming Language", type_slug: "programming-language", parent_id: nil, color: "grey", icon: "⌨️", keys: %i[javascript] },
    { id: 121, name: "TypeScript", slug: "typescript", description: "Typed JavaScript", type_id: 3, type: "Programming Language", type_slug: "programming-language", parent_id: nil, color: "grey", icon: "⌨️" },
    { id: 130, name: "Go", slug: "go", description: "Go programming language", type_id: 3, type: "Programming Language", type_slug: "programming-language", parent_id: nil, color: "grey", icon: "⌨️" },
    { id: 131, name: "Go 1.22", slug: "go-1-22", description: "Go version 1.22", type_id: 4, type: "Language Version", type_slug: "programming-language-version", parent_id: 130, color: "grey", icon: "🔢" },
    { id: 140, name: "Java", slug: "java", description: "Java programming language", type_id: 3, type: "Programming Language", type_slug: "programming-language", parent_id: nil, color: "grey", icon: "⌨️" },
    { id: 141, name: "Java 21 (LTS)", slug: "java-21-lts", description: "Java LTS version", type_id: 4, type: "Language Version", type_slug: "programming-language-version", parent_id: 140, color: "grey", icon: "🔢" },
    { id: 150, name: "C#", slug: "c-sharp", description: "C# programming language", type_id: 3, type: "Programming Language", type_slug: "programming-language", parent_id: nil, color: "grey", icon: "⌨️" },
    { id: 151, name: ".NET 8", slug: "dotnet-8", description: ".NET runtime version", type_id: 4, type: "Language Version", type_slug: "programming-language-version", parent_id: 150, color: "grey", icon: "🔢" },
    { id: 160, name: "Rust", slug: "rust", description: "Rust programming language", type_id: 3, type: "Programming Language", type_slug: "programming-language", parent_id: nil, color: "grey", icon: "⌨️" },
    # Framework tags (tag_type_id: 5)
    { id: 200, name: "Ruby on Rails", slug: "ruby-on-rails", description: "Ruby web framework", type_id: 5, type: "Framework", type_slug: "framework", parent_id: nil, color: "green", icon: "🧩", keys: %i[rails ruby_on_rails] },
    { id: 201, name: "Rails 7.1", slug: "rails-7-1", description: "Rails framework version", type_id: 6, type: "Framework Version", type_slug: "framework-version", parent_id: 200, color: "green", icon: "🔢" },
    { id: 210, name: "Django", slug: "django", description: "Python web framework", type_id: 5, type: "Framework", type_slug: "framework", parent_id: nil, color: "green", icon: "🧩" },
    { id: 211, name: "Django 5.x", slug: "django-5", description: "Django major version", type_id: 6, type: "Framework Version", type_slug: "framework-version", parent_id: 210, color: "green", icon: "🔢" },
    { id: 220, name: "React", slug: "react", description: "UI library for web apps", type_id: 5, type: "Framework", type_slug: "framework", parent_id: nil, color: "green", icon: "🧩", keys: %i[react] },
    { id: 221, name: "Next.js", slug: "nextjs", description: "React meta-framework", type_id: 5, type: "Framework", type_slug: "framework", parent_id: 220, color: "green", icon: "🧩" },
    { id: 222, name: "Next.js 14", slug: "nextjs-14", description: "Next.js version 14", type_id: 6, type: "Framework Version", type_slug: "framework-version", parent_id: 221, color: "green", icon: "🔢" },
    { id: 230, name: "Vue", slug: "vue", description: "Frontend framework", type_id: 5, type: "Framework", type_slug: "framework", parent_id: nil, color: "green", icon: "🧩" },
    { id: 231, name: "Nuxt", slug: "nuxt", description: "Vue meta-framework", type_id: 5, type: "Framework", type_slug: "framework", parent_id: 230, color: "green", icon: "🧩" },
    { id: 240, name: "Svelte", slug: "svelte", description: "Compiler-based frontend framework", type_id: 5, type: "Framework", type_slug: "framework", parent_id: nil, color: "green", icon: "🧩" },
    { id: 241, name: "SvelteKit", slug: "sveltekit", description: "Svelte meta-framework", type_id: 5, type: "Framework", type_slug: "framework", parent_id: 240, color: "green", icon: "🧩" },
    # Dev Tool tags (tag_type_id: 7)
    { id: 300, name: "Git", slug: "git", description: "Version control system", type_id: 7, type: "Dev Tool", type_slug: "dev-tool", parent_id: nil, color: "indigo", icon: "🛠️" },
    { id: 301, name: "Docker", slug: "docker", description: "Container platform", type_id: 7, type: "Dev Tool", type_slug: "dev-tool", parent_id: nil, color: "indigo", icon: "🛠️" },
    { id: 302, name: "Kubernetes", slug: "kubernetes", description: "Container orchestration", type_id: 7, type: "Dev Tool", type_slug: "dev-tool", parent_id: nil, color: "indigo", icon: "🛠️", keys: %i[kubernetes] },
    { id: 303, name: "Postman", slug: "postman", description: "API testing tool", type_id: 7, type: "Dev Tool", type_slug: "dev-tool", parent_id: nil, color: "indigo", icon: "🛠️" },
    # Database tags (tag_type_id: 8)
    { id: 400, name: "PostgreSQL", slug: "postgresql", description: "Relational database", type_id: 8, type: "Database", type_slug: "database", parent_id: nil, color: "navy", icon: "🗄️", keys: %i[postgres postgresql] },
    { id: 401, name: "MySQL", slug: "mysql", description: "Relational database", type_id: 8, type: "Database", type_slug: "database", parent_id: nil, color: "navy", icon: "🗄️" },
    { id: 402, name: "SQLite", slug: "sqlite", description: "Embedded database", type_id: 8, type: "Database", type_slug: "database", parent_id: nil, color: "navy", icon: "🗄️" },
    { id: 403, name: "Redis", slug: "redis", description: "In-memory data store", type_id: 8, type: "Database", type_slug: "database", parent_id: nil, color: "navy", icon: "🗄️" },
    { id: 404, name: "MongoDB", slug: "mongodb", description: "Document database", type_id: 8, type: "Database", type_slug: "database", parent_id: nil, color: "navy", icon: "🗄️" },
    # Cloud Platform tags (tag_type_id: 9)
    { id: 600, name: "AWS", slug: "aws", description: "Amazon Web Services", type_id: 9, type: "Cloud Platform", type_slug: "cloud-platform", parent_id: nil, color: "purple", icon: "☁️" },
    { id: 601, name: "AWS Lambda", slug: "aws-lambda", description: "Serverless compute", type_id: 10, type: "Cloud Service", type_slug: "cloud-service", parent_id: 600, color: "purple", icon: "🔧" },
    { id: 602, name: "AWS S3", slug: "aws-s3", description: "Object storage", type_id: 10, type: "Cloud Service", type_slug: "cloud-service", parent_id: 600, color: "purple", icon: "🔧" },
    { id: 610, name: "Google Cloud", slug: "google-cloud", description: "Google Cloud Platform", type_id: 9, type: "Cloud Platform", type_slug: "cloud-platform", parent_id: nil, color: "purple", icon: "☁️" },
    { id: 611, name: "Cloud Run", slug: "cloud-run", description: "Serverless containers", type_id: 10, type: "Cloud Service", type_slug: "cloud-service", parent_id: 610, color: "purple", icon: "🔧" },
    # Topic tags (tag_type_id: 11)
    { id: 700, name: "Web Development", slug: "web-development", description: "Building web applications", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠" },
    { id: 701, name: "Backend", slug: "backend", description: "Server-side development", type_id: 11, type: "Topic", type_slug: "topic", parent_id: 700, color: "cyan", icon: "🧠", keys: %i[backend] },
    { id: 702, name: "Frontend", slug: "frontend", description: "Client-side development", type_id: 11, type: "Topic", type_slug: "topic", parent_id: 700, color: "cyan", icon: "🧠", keys: %i[frontend] },
    { id: 710, name: "APIs", slug: "apis", description: "API design and usage", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠" },
    { id: 711, name: "REST", slug: "rest", description: "RESTful APIs", type_id: 11, type: "Topic", type_slug: "topic", parent_id: 710, color: "cyan", icon: "🧠" },
    { id: 712, name: "GraphQL", slug: "graphql", description: "GraphQL APIs", type_id: 11, type: "Topic", type_slug: "topic", parent_id: 710, color: "cyan", icon: "🧠" },
    { id: 720, name: "Testing", slug: "testing", description: "Software testing", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠", keys: %i[testing] },
    { id: 721, name: "Unit Testing", slug: "unit-testing", description: "Unit tests", type_id: 11, type: "Topic", type_slug: "topic", parent_id: 720, color: "cyan", icon: "🧠" },
    { id: 722, name: "E2E Testing", slug: "e2e-testing", description: "End-to-end tests", type_id: 11, type: "Topic", type_slug: "topic", parent_id: 720, color: "cyan", icon: "🧠" },
    { id: 730, name: "Security", slug: "security", description: "Application security", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠" },
    { id: 731, name: "OWASP", slug: "owasp", description: "OWASP standards", type_id: 11, type: "Topic", type_slug: "topic", parent_id: 730, color: "cyan", icon: "🧠" },
    { id: 740, name: "Performance", slug: "performance", description: "Optimization and speed", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠" },
    { id: 750, name: "System Design", slug: "system-design", description: "Architecture and scaling", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠" },
    { id: 760, name: "Productivity", slug: "productivity", description: "Developer experience and workflow speed", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠", keys: %i[productivity] },
    { id: 761, name: "Data", slug: "data", description: "Data engineering and analytics", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠", keys: %i[data] },
    { id: 762, name: "AI", slug: "ai", description: "Artificial intelligence", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠", keys: %i[ai] },
    { id: 763, name: "LLM", slug: "llm", description: "Large language models", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠", keys: %i[llm] },
    { id: 764, name: "DevOps", slug: "devops", description: "Infrastructure automation and delivery", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠", keys: %i[devops] },
    { id: 765, name: "Observability", slug: "observability", description: "Monitoring, logging, and tracing", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠", keys: %i[observability] },
    { id: 766, name: "Framework", slug: "framework", description: "General framework classification", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠", keys: %i[framework] },
    { id: 767, name: "Language", slug: "language", description: "General programming language classification", type_id: 11, type: "Topic", type_slug: "topic", parent_id: nil, color: "cyan", icon: "🧠", keys: %i[language] },
    # Task tags (tag_type_id: 12)
    { id: 800, name: "Getting Started", slug: "getting-started", description: "Beginner introductions", type_id: 12, type: "Task", type_slug: "task", parent_id: nil, color: "blue", icon: "✅" },
    { id: 801, name: "Setup / Install", slug: "setup-install", description: "Installation instructions", type_id: 12, type: "Task", type_slug: "task", parent_id: nil, color: "blue", icon: "✅" },
    { id: 802, name: "Debugging", slug: "debugging", description: "Finding and fixing bugs", type_id: 12, type: "Task", type_slug: "task", parent_id: nil, color: "blue", icon: "✅" },
    { id: 803, name: "Deployment", slug: "deployment", description: "Shipping to production", type_id: 12, type: "Task", type_slug: "task", parent_id: nil, color: "blue", icon: "✅" },
    { id: 804, name: "Best Practices", slug: "best-practices", description: "Recommended patterns", type_id: 12, type: "Task", type_slug: "task", parent_id: nil, color: "blue", icon: "✅" },
    { id: 805, name: "Migration / Upgrade", slug: "migration-upgrade", description: "Updating versions", type_id: 12, type: "Task", type_slug: "task", parent_id: nil, color: "blue", icon: "✅" },
    # Level tags (tag_type_id: 13)
    { id: 900, name: "Beginner", slug: "beginner", description: "Beginner-friendly content", type_id: 13, type: "Level", type_slug: "level", parent_id: nil, color: "light green", icon: "🎚️" },
    { id: 901, name: "Intermediate", slug: "intermediate", description: "Intermediate difficulty", type_id: 13, type: "Level", type_slug: "level", parent_id: nil, color: "light orange", icon: "🎚️" },
    { id: 902, name: "Advanced", slug: "advanced", description: "Advanced-level content", type_id: 13, type: "Level", type_slug: "level", parent_id: nil, color: "light red", icon: "🎚️" }
  ]

  # First pass: create all tags without parent relationships
  tag_defs.each do |attrs|
    # Always check by name first to avoid uniqueness validation errors
    # This ensures we update existing tags instead of trying to create duplicates
    tag = Tag.find_by("LOWER(tag_name) = ?", attrs[:name].downcase)
    
    if tag.nil?
      # No tag with this name exists - check if we can use the specified ID
      existing_tag_with_id = Tag.find_by(id: attrs[:id])
      if existing_tag_with_id
        # ID is taken by a different tag - create new tag without specifying ID
        tag = Tag.new
        Rails.logger.info "Tag ID #{attrs[:id]} is taken by '#{existing_tag_with_id.tag_name}', creating new tag for '#{attrs[:name]}'"
      else
        # ID is available - create new tag with specified ID
        tag = Tag.new(id: attrs[:id])
      end
    else
      # Tag exists - log if ID doesn't match
      if tag.id != attrs[:id]
        Rails.logger.info "Tag '#{attrs[:name]}' exists with ID #{tag.id}, seed expects ID #{attrs[:id]}. Using existing tag."
      end
    end
    
    tag.tag_name = attrs[:name]
    tag.tag_slug = attrs[:slug]
    tag.tag_description = attrs[:description]
    tag.tag_type_id = attrs[:type_id]
    tag.tag_type = attrs[:type]
    tag.tag_type_slug = attrs[:type_slug]
    tag.color = attrs[:color]
    tag.icon = attrs[:icon]
    tag.tag_alias = nil # Not provided in seed data
    tag.save!
    
    # Map the seed ID to the tag (may be different if tag existed with different ID)
    tags_by_id[attrs[:id]] = tag
  end

  # Second pass: set parent relationships
  tag_defs.each do |attrs|
    next unless attrs[:parent_id]

    tag = tags_by_id[attrs[:id]]
    parent_tag = tags_by_id[attrs[:parent_id]]
    if parent_tag
      tag.parent_id = parent_tag.id
      tag.save!
    end
  end

  # Build lookup aliases so attach_tags can seed ToolTag/SubmissionTag rows
  tag_defs.each do |attrs|
    tag = tags_by_id[attrs[:id]]
    next unless tag

    key_aliases = Array(attrs[:keys]).compact
    key_aliases << attrs[:slug]&.tr("-", "_")&.to_sym
    key_aliases << attrs[:name]&.parameterize(separator: "_")&.to_sym
    key_aliases.compact.uniq.each do |key|
      tags[key] = tag
    end
  end

  # Tools (community-owned). Disable discovery job while seeding to keep it fast.
  log_step "Creating tools"
  tool_callback_disabled = false
  if Tool.respond_to?(:skip_callback)
    Tool.skip_callback(:create, :after, :enqueue_discovery_job)
    tool_callback_disabled = true
  end

  tools = {}
  tool_defs = [
    { key: :rails, name: "Ruby on Rails", url: "https://rubyonrails.org", desc: "Full-stack framework with Hotwire and Turbo.", note: "Default stack for internal apps.", tags: %i[ruby rails backend], created_at: 8.days.ago },
    { key: :turbo, name: "Turbo", url: "https://turbo.hotwired.dev", desc: "HTML-over-the-wire for fast, low-JS apps.", note: "Great fit for server-first UI.", tags: %i[rails frontend productivity], created_at: 6.days.ago },
    { key: :stimulus, name: "Stimulus", url: "https://stimulus.hotwired.dev", desc: "Sprinkle-on JS framework from Basecamp.", note: "Pairs well with Turbo.", tags: %i[frontend productivity], created_at: 6.days.ago },
    { key: :postgres, name: "PostgreSQL", url: "https://www.postgresql.org", desc: "Battle-tested relational database.", note: "Primary DB with pgvector.", tags: %i[postgres backend], created_at: 12.days.ago },
    { key: :pgvector, name: "pgvector", url: "https://github.com/pgvector/pgvector", desc: "Vector embeddings inside Postgres.", note: "Enables semantic search.", tags: %i[data backend], created_at: 10.days.ago },
    { key: :k8s, name: "Kubernetes", url: "https://kubernetes.io", desc: "Container orchestration platform.", note: "Used for deployment simulations.", tags: %i[kubernetes devops], created_at: 14.days.ago },
    { key: :docker, name: "Docker", url: "https://www.docker.com", desc: "Container runtime and tooling.", note: "Local dev environments.", tags: %i[devops], created_at: 15.days.ago },
    { key: :gha, name: "GitHub Actions", url: "https://github.com/features/actions", desc: "GitHub-native CI/CD.", note: "Reusable workflows for checks.", tags: %i[devops testing], created_at: 9.days.ago },
    { key: :prometheus, name: "Prometheus", url: "https://prometheus.io", desc: "Metrics and alerting toolkit.", note: "Feeds Grafana dashboards.", tags: %i[observability devops], created_at: 11.days.ago },
    { key: :grafana, name: "Grafana", url: "https://grafana.com", desc: "Observability dashboards.", note: "Pairs with Prometheus and Loki.", tags: %i[observability devops], created_at: 9.days.ago },
    { key: :langchain, name: "LangChain", url: "https://python.langchain.com", desc: "LLM orchestration library.", note: "Used for agent experiments.", tags: %i[ai llm python], created_at: 7.days.ago },
    { key: :openai, name: "OpenAI API", url: "https://platform.openai.com", desc: "GPT models and embeddings.", note: "Default LLM provider.", tags: %i[ai llm], created_at: 7.days.ago },
    { key: :pytest, name: "Pytest", url: "https://docs.pytest.org", desc: "Python testing framework.", note: "Fast tests and fixtures.", tags: %i[python testing], created_at: 5.days.ago },
    { key: :react, name: "React", url: "https://react.dev", desc: "Component-based UI library.", note: "Used for comparison to Hotwire.", tags: %i[react frontend javascript], created_at: 16.days.ago },
    { key: :vite, name: "Vite", url: "https://vitejs.dev", desc: "Next generation frontend tooling.", note: "Fast HMR and optimized builds.", tags: %i[frontend javascript productivity], created_at: 4.days.ago },
    { key: :typescript, name: "TypeScript", url: "https://www.typescriptlang.org", desc: "Typed superset of JavaScript.", note: "Better DX with type safety.", tags: %i[javascript language], created_at: 13.days.ago },
    { key: :nextjs, name: "Next.js", url: "https://nextjs.org", desc: "React framework for production.", note: "SSR, SSG, and API routes.", tags: %i[react frontend framework], created_at: 11.days.ago },
    { key: :tailwind, name: "Tailwind CSS", url: "https://tailwindcss.com", desc: "Utility-first CSS framework.", note: "Rapid UI development.", tags: %i[frontend productivity], created_at: 7.days.ago },
    { key: :redis, name: "Redis", url: "https://redis.io", desc: "In-memory data structure store.", note: "Caching and session storage.", tags: %i[backend data], created_at: 10.days.ago },
    { key: :elasticsearch, name: "Elasticsearch", url: "https://www.elastic.co/elasticsearch", desc: "Distributed search and analytics engine.", note: "Full-text search and logging.", tags: %i[data backend], created_at: 12.days.ago },
    { key: :terraform, name: "Terraform", url: "https://www.terraform.io", desc: "Infrastructure as code tool.", note: "Multi-cloud provisioning.", tags: %i[devops], created_at: 15.days.ago },
    { key: :ansible, name: "Ansible", url: "https://www.ansible.com", desc: "Configuration management automation.", note: "Agentless orchestration.", tags: %i[devops], created_at: 13.days.ago },
    { key: :jenkins, name: "Jenkins", url: "https://www.jenkins.io", desc: "Automation server for CI/CD.", note: "Extensible with plugins.", tags: %i[devops testing], created_at: 14.days.ago },
    { key: :sentry, name: "Sentry", url: "https://sentry.io", desc: "Error tracking and performance monitoring.", note: "Real-time error alerts.", tags: %i[observability devops], created_at: 8.days.ago },
    { key: :datadog, name: "Datadog", url: "https://www.datadoghq.com", desc: "Monitoring and security platform.", note: "APM, logs, and metrics.", tags: %i[observability devops], created_at: 6.days.ago },
    { key: :jupyter, name: "Jupyter", url: "https://jupyter.org", desc: "Interactive computing notebooks.", note: "Data science and ML workflows.", tags: %i[data ai python], created_at: 9.days.ago }
  ]

  tool_defs.each do |attrs|
    tool = Tool.find_or_initialize_by(tool_name: attrs[:name])
    tool.assign_attributes(
      tool_description: attrs[:desc],
      tool_url: attrs[:url],
      author_note: attrs[:note],
      visibility: :public
    )
    tool.created_at = attrs[:created_at] if tool.new_record?
    tool.save!
    attach_tags(tool, attrs[:tags], tags)
    tools[attrs[:key]] = tool
  end

  # Submissions (user-owned content about tools)
  log_step "Creating submissions"
  submissions = {}
  submission_defs = [
    {
      key: :hotwire_dashboard,
      user: :alice,
      name: "Building a dashboard with Hotwire",
      url: "https://example.com/hotwire-dashboard",
      desc: "End-to-end guide using Turbo Streams and Stimulus for live updates.",
      note: "Shows server-first patterns with minimal JS.",
      type: :article,
      status: :completed,
      tools: %i[rails turbo stimulus],
      tags: %i[frontend rails],
      created_at: 4.days.ago
    },
    {
      key: :pgvector_search,
      user: :diana,
      name: "Semantic search with pgvector",
      url: "https://example.com/pgvector-search",
      desc: "How to store embeddings in Postgres and query with cosine similarity.",
      note: "Includes migration patterns and benchmarks.",
      type: :guide,
      status: :completed,
      tools: %i[pgvector postgres openai],
      tags: %i[data ai backend],
      created_at: 3.days.ago
    },
    {
      key: :gha_ci,
      user: :bob,
      name: "Reusable GitHub Actions for Rails",
      url: "https://example.com/gha-rails",
      desc: "Reusable workflow for lint, test, and security scans.",
      note: "Demonstrates matrix builds and caching.",
      type: :documentation,
      status: :completed,
      tools: %i[gha rails],
      tags: %i[devops testing backend],
      created_at: 5.days.ago
    },
    {
      key: :k8s_deploy,
      user: :bob,
      name: "Blue/green deploys on Kubernetes",
      url: "https://example.com/k8s-blue-green",
      desc: "Traffic shifting with services and readiness probes.",
      note: "Good starter manifest templates.",
      type: :guide,
      status: :completed,
      tools: %i[k8s docker],
      tags: %i[devops kubernetes],
      created_at: 8.days.ago
    },
    {
      key: :react_vs_turbo,
      user: :charlie,
      name: "When to pick Turbo vs React",
      url: "https://example.com/turbo-vs-react",
      desc: "Trade-offs of server-first vs client-heavy stacks.",
      note: "Benchmarks and DX comparison.",
      type: :article,
      status: :completed,
      tools: %i[turbo react],
      tags: %i[frontend productivity],
      created_at: 2.days.ago
    },
    {
      key: :langchain_agents,
      user: :diana,
      name: "Building retrieval agents with LangChain",
      url: "https://example.com/langchain-agents",
      desc: "Chaining tools, vector search, and streaming responses.",
      note: "Pairs with pgvector storage.",
      type: :github_repo,
      status: :completed,
      tools: %i[langchain pgvector openai],
      tags: %i[ai llm data],
      created_at: 6.days.ago
    },
    {
      key: :pytest_patterns,
      user: :diana,
      name: "Pytest patterns for service tests",
      url: "https://example.com/pytest-patterns",
      desc: "Fixtures, parametrization, and parallel runs.",
      note: "Applies to FastAPI and Django.",
      type: :article,
      status: :completed,
      tools: %i[pytest],
      tags: %i[python testing backend],
      created_at: 4.days.ago
    },
    {
      key: :observability_stack,
      user: :eve,
      name: "Observability stack quickstart",
      url: "https://example.com/observability-stack",
      desc: "Prometheus + Grafana dashboards with alerts.",
      note: "Includes sample dashboards.",
      type: :guide,
      status: :completed,
      tools: %i[prometheus grafana],
      tags: %i[observability devops],
      created_at: 1.day.ago
    },
    {
      key: :vite_setup,
      user: :charlie,
      name: "Setting up Vite with React",
      url: "https://example.com/vite-react-setup",
      desc: "Quick start guide for Vite + React development.",
      note: "Includes TypeScript configuration.",
      type: :guide,
      status: :completed,
      tools: %i[vite react typescript],
      tags: %i[frontend javascript],
      created_at: 3.days.ago
    },
    {
      key: :nextjs_ssr,
      user: :charlie,
      name: "Next.js SSR patterns",
      url: "https://example.com/nextjs-ssr",
      desc: "Server-side rendering best practices and performance tips.",
      note: "Covers ISR and edge functions.",
      type: :article,
      status: :completed,
      tools: %i[nextjs react],
      tags: %i[frontend productivity],
      created_at: 2.days.ago
    },
    {
      key: :tailwind_components,
      user: :ivy,
      name: "Building reusable Tailwind components",
      url: "https://example.com/tailwind-components",
      desc: "Component library patterns with Tailwind CSS.",
      note: "Includes dark mode support.",
      type: :guide,
      status: :completed,
      tools: %i[tailwind],
      tags: %i[frontend productivity],
      created_at: 4.days.ago
    },
    {
      key: :redis_caching,
      user: :henry,
      name: "Redis caching strategies",
      url: "https://example.com/redis-caching",
      desc: "Implementing effective caching layers with Redis.",
      note: "Covers cache invalidation patterns.",
      type: :article,
      status: :completed,
      tools: %i[redis backend],
      tags: %i[backend data],
      created_at: 5.days.ago
    },
    {
      key: :elasticsearch_search,
      user: :henry,
      name: "Full-text search with Elasticsearch",
      url: "https://example.com/elasticsearch-search",
      desc: "Building search features with Elasticsearch queries.",
      note: "Includes relevance tuning examples.",
      type: :guide,
      status: :completed,
      tools: %i[elasticsearch],
      tags: %i[data backend],
      created_at: 6.days.ago
    },
    {
      key: :terraform_aws,
      user: :bob,
      name: "Terraform AWS infrastructure",
      url: "https://example.com/terraform-aws",
      desc: "Provisioning AWS resources with Terraform modules.",
      note: "Multi-region deployment patterns.",
      type: :guide,
      status: :completed,
      tools: %i[terraform k8s],
      tags: %i[devops],
      created_at: 7.days.ago
    },
    {
      key: :ansible_playbooks,
      user: :bob,
      name: "Ansible playbooks for deployment",
      url: "https://example.com/ansible-playbooks",
      desc: "Automating server configuration with Ansible.",
      note: "Idempotent playbook examples.",
      type: :documentation,
      status: :completed,
      tools: %i[ansible],
      tags: %i[devops],
      created_at: 8.days.ago
    },
    {
      key: :jenkins_pipelines,
      user: :jack,
      name: "Jenkins CI/CD pipelines",
      url: "https://example.com/jenkins-pipelines",
      desc: "Building robust CI/CD workflows with Jenkins.",
      note: "Declarative pipeline examples.",
      type: :guide,
      status: :completed,
      tools: %i[jenkins],
      tags: %i[devops testing],
      created_at: 9.days.ago
    },
    {
      key: :sentry_integration,
      user: :liam,
      name: "Error tracking with Sentry",
      url: "https://example.com/sentry-integration",
      desc: "Setting up Sentry for production error monitoring.",
      note: "Includes release tracking and source maps.",
      type: :guide,
      status: :completed,
      tools: %i[sentry],
      tags: %i[observability devops],
      created_at: 10.days.ago
    },
    {
      key: :datadog_dashboards,
      user: :liam,
      name: "Datadog monitoring dashboards",
      url: "https://example.com/datadog-dashboards",
      desc: "Creating comprehensive monitoring dashboards.",
      note: "APM and log correlation examples.",
      type: :article,
      status: :completed,
      tools: %i[datadog],
      tags: %i[observability devops],
      created_at: 11.days.ago
    },
    {
      key: :jupyter_notebooks,
      user: :kate,
      name: "Jupyter notebooks for ML workflows",
      url: "https://example.com/jupyter-ml",
      desc: "Organizing ML experiments with Jupyter notebooks.",
      note: "Best practices for reproducible research.",
      type: :guide,
      status: :completed,
      tools: %i[jupyter python],
      tags: %i[ai data],
      created_at: 12.days.ago
    },
    {
      key: :typescript_advanced,
      user: :charlie,
      name: "Advanced TypeScript patterns",
      url: "https://example.com/typescript-advanced",
      desc: "Generics, conditional types, and utility types.",
      note: "Real-world examples from production code.",
      type: :article,
      status: :completed,
      tools: %i[typescript],
      tags: %i[javascript language],
      created_at: 13.days.ago
    },
    {
      key: :react_native_setup,
      user: :grace,
      name: "React Native development setup",
      url: "https://example.com/react-native-setup",
      desc: "Getting started with React Native for mobile apps.",
      note: "iOS and Android configuration.",
      type: :guide,
      status: :completed,
      tools: %i[react],
      tags: %i[frontend],
      created_at: 14.days.ago
    },
    {
      key: :microservices_architecture,
      user: :henry,
      name: "Microservices architecture patterns",
      url: "https://example.com/microservices-patterns",
      desc: "Designing scalable microservices systems.",
      note: "Service communication and data consistency.",
      type: :article,
      status: :completed,
      tools: %i[k8s docker],
      tags: %i[backend devops],
      created_at: 15.days.ago
    },
    {
      key: :ml_pipelines,
      user: :kate,
      name: "Building ML pipelines with Python",
      url: "https://example.com/ml-pipelines",
      desc: "End-to-end ML pipeline from data to deployment.",
      note: "Includes model versioning and monitoring.",
      type: :guide,
      status: :completed,
      tools: %i[python jupyter],
      tags: %i[ai data],
      created_at: 16.days.ago
    },
    {
      key: :api_design,
      user: :mia,
      name: "RESTful API design principles",
      url: "https://example.com/api-design",
      desc: "Best practices for designing REST APIs.",
      note: "Versioning, pagination, and error handling.",
      type: :article,
      status: :completed,
      tools: %i[rails],
      tags: %i[backend],
      created_at: 17.days.ago
    },
    {
      key: :distributed_systems,
      user: :mia,
      name: "Distributed systems fundamentals",
      url: "https://example.com/distributed-systems",
      desc: "Consistency, availability, and partition tolerance.",
      note: "CAP theorem and practical trade-offs.",
      type: :article,
      status: :completed,
      tools: %i[k8s],
      tags: %i[backend devops],
      created_at: 18.days.ago
    }
  ]

  submission_defs.each do |attrs|
    submission = Submission.find_or_initialize_by(submission_url: attrs[:url], user: users[attrs[:user]])
    submission.assign_attributes(
      submission_name: attrs[:name],
      submission_description: attrs[:desc],
      author_note: attrs[:note],
      submission_type: attrs[:type],
      status: attrs[:status] || :completed
    )
    submission.created_at = attrs[:created_at] if submission.new_record?
    submission.save!
    Array(attrs[:tools]).each do |tool_key|
      tool = tools[tool_key]
      submission.tools << tool if tool && !submission.tools.include?(tool)
    end
    attach_tags(submission, attrs[:tags], tags)
    submissions[attrs[:key]] = submission
  end

  # Lists (tools + submissions)
  log_step "Creating lists"
  lists = {}
  list_defs = [
    { key: :rails_stack, user: :alice, name: "Rails & Hotwire Stack", visibility: :public, tools: %i[rails turbo stimulus], submissions: %i[hotwire_dashboard gha_ci] },
    { key: :platform_ops, user: :bob, name: "Platform Ops", visibility: :public, tools: %i[docker k8s gha], submissions: %i[k8s_deploy observability_stack] },
    { key: :ai_retrieval, user: :diana, name: "AI Retrieval Recipes", visibility: :public, tools: %i[langchain pgvector openai], submissions: %i[pgvector_search langchain_agents] },
    { key: :frontend_choices, user: :charlie, name: "Frontend Choices", visibility: :public, tools: %i[react turbo stimulus], submissions: %i[react_vs_turbo] },
    { key: :security_watch, user: :eve, name: "Security & Reliability", visibility: :private, tools: %i[gha prometheus], submissions: %i[observability_stack] },
    { key: :archived, user: :ghost, name: "Archived Picks", visibility: :private, tools: %i[react], submissions: [] }
  ]

  list_defs.each do |attrs|
    list = List.find_or_initialize_by(user: users[attrs[:user]], list_name: attrs[:name])
    list.visibility = attrs[:visibility] || :public
    list.list_type ||= 0
    list.save!

    Array(attrs[:tools]).each do |tool_key|
      tool = tools[tool_key]
      list.tools << tool if tool && !list.tools.include?(tool)
    end

    Array(attrs[:submissions]).each do |submission_key|
      submission = submissions[submission_key]
      list.submissions << submission if submission && !list.submissions.include?(submission)
    end

    lists[attrs[:key]] = list
  end

  # User -> Tool interactions (upvotes/favorites/read)
  log_step "Creating user-tool interactions"
  user_tool_defs = [
    { user: :alice, tool: :rails, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :alice, tool: :turbo, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :alice, tool: :stimulus, upvote: true, read_at: 3.days.ago },
    { user: :bob, tool: :docker, upvote: true, favorite: true, read_at: 7.days.ago },
    { user: :bob, tool: :k8s, upvote: true, favorite: true, read_at: 6.days.ago },
    { user: :bob, tool: :gha, upvote: true, read_at: 5.days.ago },
    { user: :charlie, tool: :react, upvote: true, favorite: true, read_at: 6.days.ago },
    { user: :charlie, tool: :turbo, upvote: true, read_at: 2.days.ago },
    { user: :diana, tool: :pgvector, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :diana, tool: :openai, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :diana, tool: :langchain, upvote: true, read_at: 2.days.ago },
    { user: :eve, tool: :prometheus, upvote: true, favorite: true, read_at: 1.day.ago },
    { user: :eve, tool: :grafana, upvote: true, read_at: 1.day.ago },
    { user: :frank, tool: :rails, upvote: true, read_at: 2.days.ago },
    { user: :grace, tool: :react, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :grace, tool: :vite, upvote: true, read_at: 2.days.ago },
    { user: :henry, tool: :redis, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :henry, tool: :elasticsearch, upvote: true, read_at: 5.days.ago },
    { user: :henry, tool: :postgres, upvote: true, read_at: 6.days.ago },
    { user: :ivy, tool: :tailwind, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :ivy, tool: :react, upvote: true, read_at: 4.days.ago },
    { user: :jack, tool: :jenkins, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :jack, tool: :gha, upvote: true, read_at: 6.days.ago },
    { user: :kate, tool: :jupyter, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :kate, tool: :langchain, upvote: true, read_at: 3.days.ago },
    { user: :kate, tool: :openai, upvote: true, read_at: 2.days.ago },
    { user: :liam, tool: :sentry, upvote: true, favorite: true, read_at: 1.day.ago },
    { user: :liam, tool: :datadog, upvote: true, read_at: 2.days.ago },
    { user: :liam, tool: :prometheus, upvote: true, read_at: 3.days.ago },
    { user: :mia, tool: :terraform, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :mia, tool: :k8s, upvote: true, read_at: 6.days.ago },
    { user: :mia, tool: :docker, upvote: true, read_at: 7.days.ago }
  ]

  user_tool_defs.each do |attrs|
    ut = UserTool.find_or_initialize_by(user: users[attrs[:user]], tool: tools[attrs[:tool]])
    ut.upvote = attrs[:upvote] || false
    ut.favorite = attrs[:favorite] || false
    ut.read_at = attrs[:read_at]
    ut.save!
  end

  # User -> Submission interactions
  log_step "Creating user-submission interactions"
  user_submission_defs = [
    { user: :alice, submission: :hotwire_dashboard, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :alice, submission: :pgvector_search, upvote: true, read_at: 2.days.ago },
    { user: :bob, submission: :gha_ci, upvote: true, read_at: 4.days.ago },
    { user: :bob, submission: :k8s_deploy, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :charlie, submission: :react_vs_turbo, upvote: true, favorite: true, read_at: 1.day.ago },
    { user: :diana, submission: :langchain_agents, upvote: true, favorite: true, read_at: 2.days.ago },
    { user: :diana, submission: :pgvector_search, upvote: true, read_at: 2.days.ago },
    { user: :eve, submission: :observability_stack, upvote: true, favorite: true, read_at: 12.hours.ago },
    { user: :charlie, submission: :vite_setup, upvote: true, favorite: true, read_at: 2.days.ago },
    { user: :charlie, submission: :nextjs_ssr, upvote: true, read_at: 1.day.ago },
    { user: :ivy, submission: :tailwind_components, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :henry, submission: :redis_caching, upvote: true, read_at: 4.days.ago },
    { user: :henry, submission: :elasticsearch_search, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :bob, submission: :terraform_aws, upvote: true, read_at: 6.days.ago },
    { user: :bob, submission: :ansible_playbooks, upvote: true, favorite: true, read_at: 7.days.ago },
    { user: :jack, submission: :jenkins_pipelines, upvote: true, read_at: 8.days.ago },
    { user: :liam, submission: :sentry_integration, upvote: true, favorite: true, read_at: 9.days.ago },
    { user: :liam, submission: :datadog_dashboards, upvote: true, read_at: 10.days.ago },
    { user: :kate, submission: :jupyter_notebooks, upvote: true, favorite: true, read_at: 11.days.ago },
    { user: :charlie, submission: :typescript_advanced, upvote: true, read_at: 12.days.ago },
    { user: :grace, submission: :react_native_setup, upvote: true, favorite: true, read_at: 13.days.ago },
    { user: :henry, submission: :microservices_architecture, upvote: true, read_at: 14.days.ago },
    { user: :kate, submission: :ml_pipelines, upvote: true, favorite: true, read_at: 15.days.ago },
    { user: :mia, submission: :api_design, upvote: true, read_at: 16.days.ago },
    { user: :mia, submission: :distributed_systems, upvote: true, favorite: true, read_at: 17.days.ago }
  ]

  user_submission_defs.each do |attrs|
    us = UserSubmission.find_or_initialize_by(user: users[attrs[:user]], submission: submissions[attrs[:submission]])
    us.upvote = attrs[:upvote] || false
    us.favorite = attrs[:favorite] || false
    us.read_at = attrs[:read_at]
    us.save!
  end

  # Follows (tools, lists, tags, users)
  log_step "Creating follows"
  follow_defs = [
    { user: :alice, followable: tools[:pgvector] },
    { user: :alice, followable: lists[:ai_retrieval] },
    { user: :bob, followable: tools[:rails] },
    { user: :bob, followable: lists[:rails_stack] },
    { user: :charlie, followable: tags[:frontend] },
    { user: :charlie, followable: lists[:frontend_choices] },
    { user: :diana, followable: tags[:ai] },
    { user: :diana, followable: tools[:openai] },
    { user: :eve, followable: lists[:platform_ops] },
    { user: :eve, followable: tools[:gha] },
    { user: :frank, followable: users[:alice] },
    { user: :frank, followable: lists[:rails_stack] },
    { user: :grace, followable: tools[:react] },
    { user: :grace, followable: tools[:vite] },
    { user: :henry, followable: tools[:redis] },
    { user: :henry, followable: tools[:elasticsearch] },
    { user: :ivy, followable: tools[:tailwind] },
    { user: :ivy, followable: tags[:frontend] },
    { user: :jack, followable: tools[:jenkins] },
    { user: :jack, followable: tags[:testing] },
    { user: :kate, followable: tools[:jupyter] },
    { user: :kate, followable: tags[:ai] },
    { user: :liam, followable: tools[:sentry] },
    { user: :liam, followable: tools[:datadog] },
    { user: :mia, followable: tools[:terraform] },
    { user: :mia, followable: users[:henry] }
  ]

  follow_defs.each do |attrs|
    user = users[attrs[:user]]
    followable = attrs[:followable]
    next unless user && followable
    next if followable.is_a?(List) && followable.user_id == user.id # guard against self-follow validation

    Follow.find_or_create_by!(user:, followable:)
  end

  # Comments (polymorphic: tools + submissions)
  log_step "Creating comments"
  comments = []
  comment_defs = [
    { user: :alice, commentable: tools[:rails], body: "Hotwire keeps us fast without a SPA.", created_at: 4.days.ago },
    { user: :charlie, commentable: tools[:react], body: "Still great for complex client state.", created_at: 5.days.ago },
    { user: :diana, commentable: submissions[:pgvector_search], body: "Loved the migration snippet with cosine index.", created_at: 2.days.ago },
    { user: :bob, commentable: submissions[:k8s_deploy], body: "Blue/green example works well with Argo Rollouts.", created_at: 3.days.ago },
    { user: :eve, commentable: submissions[:observability_stack], body: "Please share the alert rules!", created_at: 1.day.ago },
    { user: :alice, commentable: submissions[:react_vs_turbo], body: "Benchmarks were super helpful.", created_at: 1.day.ago, parent: 1 },
    { user: :charlie, commentable: tools[:vite], body: "Vite's HMR is incredibly fast. Game changer for development.", created_at: 2.days.ago },
    { user: :grace, commentable: tools[:vite], body: "Agreed! The build times are also much better than Webpack.", created_at: 1.day.ago, parent: 6 },
    { user: :henry, commentable: tools[:redis], body: "Redis is essential for our caching layer. Great performance.", created_at: 3.days.ago },
    { user: :ivy, commentable: tools[:tailwind], body: "Tailwind makes prototyping so much faster. Love the utility classes.", created_at: 2.days.ago },
    { user: :jack, commentable: tools[:jenkins], body: "Jenkins pipelines are powerful but can get complex. Good examples here.", created_at: 4.days.ago },
    { user: :kate, commentable: tools[:jupyter], body: "Jupyter notebooks are perfect for ML experimentation and visualization.", created_at: 3.days.ago },
    { user: :liam, commentable: tools[:sentry], body: "Sentry's error grouping and release tracking saved us hours of debugging.", created_at: 2.days.ago },
    { user: :mia, commentable: tools[:terraform], body: "Terraform's state management is crucial for infrastructure as code.", created_at: 5.days.ago },
    { user: :charlie, commentable: submissions[:vite_setup], body: "This guide helped me set up Vite in minutes. Clear and concise!", created_at: 2.days.ago },
    { user: :ivy, commentable: submissions[:tailwind_components], body: "The dark mode examples are exactly what I needed. Thanks!", created_at: 3.days.ago },
    { user: :henry, commentable: submissions[:redis_caching], body: "Cache invalidation strategies are well explained here.", created_at: 4.days.ago },
    { user: :bob, commentable: submissions[:terraform_aws], body: "Multi-region deployment patterns are solid. Used this in production.", created_at: 6.days.ago },
    { user: :liam, commentable: submissions[:sentry_integration], body: "Source maps integration was tricky until I found this guide.", created_at: 9.days.ago },
    { user: :kate, commentable: submissions[:jupyter_notebooks], body: "Great tips on organizing notebooks for reproducible research.", created_at: 11.days.ago },
    { user: :charlie, commentable: submissions[:typescript_advanced], body: "Conditional types are mind-bending but this article explains them well.", created_at: 12.days.ago },
    { user: :grace, commentable: submissions[:react_native_setup], body: "iOS setup was straightforward with these instructions.", created_at: 13.days.ago },
    { user: :henry, commentable: submissions[:microservices_architecture], body: "Service communication patterns are well covered. Good reference.", created_at: 14.days.ago },
    { user: :mia, commentable: submissions[:api_design], body: "API versioning strategies are crucial. This covers all the important points.", created_at: 16.days.ago },
    { user: :diana, commentable: tools[:pgvector], body: "pgvector makes semantic search so much easier than external services.", created_at: 3.days.ago },
    { user: :bob, commentable: tools[:k8s], body: "Kubernetes has a learning curve but it's worth it for orchestration.", created_at: 7.days.ago },
    { user: :eve, commentable: tools[:prometheus], body: "Prometheus metrics are essential for observability. Great tool.", created_at: 1.day.ago },
    { user: :frank, commentable: tools[:rails], body: "Rails convention over configuration speeds up development significantly.", created_at: 2.days.ago },
    { user: :alice, commentable: submissions[:nextjs_ssr], body: "ISR is a game changer for performance. Great article!", created_at: 1.day.ago },
    { user: :charlie, commentable: submissions[:nextjs_ssr], body: "Edge functions are also worth exploring for global performance.", created_at: 1.day.ago, parent: 28 }
  ]

  comment_defs.each_with_index do |attrs, idx|
    parent_comment = attrs[:parent] ? comments[attrs[:parent]] : nil
    comment = Comment.find_or_initialize_by(
      user: users[attrs[:user]],
      commentable: attrs[:commentable],
      comment: attrs[:body]
    )
    comment.parent = parent_comment
    comment.comment_type = :comment
    comment.created_at = attrs[:created_at] if comment.new_record?
    comment.save!
    comments[idx] = comment
  end

  # Comment upvotes
  log_step "Creating comment upvotes"
  upvote_defs = [
    { user: :bob, comment: comments[0] },
    { user: :charlie, comment: comments[0] },
    { user: :alice, comment: comments[1] },
    { user: :alice, comment: comments[2] },
    { user: :diana, comment: comments[4] },
    { user: :grace, comment: comments[6] },
    { user: :ivy, comment: comments[6] },
    { user: :henry, comment: comments[8] },
    { user: :jack, comment: comments[10] },
    { user: :kate, comment: comments[11] },
    { user: :liam, comment: comments[12] },
    { user: :mia, comment: comments[13] },
    { user: :charlie, comment: comments[14] },
    { user: :ivy, comment: comments[15] },
    { user: :bob, comment: comments[17] },
    { user: :liam, comment: comments[18] },
    { user: :kate, comment: comments[19] },
    { user: :charlie, comment: comments[20] },
    { user: :grace, comment: comments[21] },
    { user: :henry, comment: comments[22] },
    { user: :mia, comment: comments[23] },
    { user: :diana, comment: comments[24] },
    { user: :bob, comment: comments[25] },
    { user: :eve, comment: comments[26] },
    { user: :frank, comment: comments[27] },
    { user: :alice, comment: comments[28] },
    { user: :charlie, comment: comments[29] }
  ]

  upvote_defs.each do |attrs|
    CommentUpvote.find_or_create_by!(user: users[attrs[:user]], comment: attrs[:comment])
  end
ensure
  Tool.set_callback(:create, :after, :enqueue_discovery_job) if tool_callback_disabled
end

# Summary
puts ""
puts "== Seed summary =="
puts "Users:         #{User.count}"
puts "Tools:         #{Tool.count}"
puts "Submissions:   #{Submission.count}"
puts "Lists:         #{List.count}"
puts "Tags:          #{Tag.count}"
puts "UserTools:     #{UserTool.count} (#{UserTool.where(upvote: true).count} upvotes, #{UserTool.where(favorite: true).count} favorites)"
puts "UserSubmissions: #{UserSubmission.count} (#{UserSubmission.where(upvote: true).count} upvotes, #{UserSubmission.where(favorite: true).count} favorites)"
puts "Follows:       #{Follow.count}"
puts "Comments:      #{Comment.count} (#{CommentUpvote.count} comment upvotes)"
puts ""
puts "Sample logins:"
puts "  - alice@example.com / #{DEFAULT_PASSWORD}"
puts "  - bob@example.com   / #{DEFAULT_PASSWORD}"
puts "  - charlie@example.com / #{DEFAULT_PASSWORD}"
puts "  - diana@example.com / #{DEFAULT_PASSWORD}"
puts "  - eve@example.com   / #{DEFAULT_PASSWORD}"
puts "  - frank@example.com / #{DEFAULT_PASSWORD}"
puts ""
puts "Seeding complete."
