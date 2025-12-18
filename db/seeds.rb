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
    { key: :rails, name: "Ruby on Rails", url: "https://rubyonrails.org", desc: "Full-stack framework with Hotwire and Turbo. Provides convention over configuration, making rapid development possible with minimal boilerplate.", note: "Default stack for internal apps. Excellent for server-first architectures.", tags: %i[ruby rails backend], created_at: 8.days.ago },
    { key: :turbo, name: "Turbo", url: "https://turbo.hotwired.dev", desc: "HTML-over-the-wire for fast, low-JS apps. Enables real-time updates without writing custom JavaScript.", note: "Great fit for server-first UI. Reduces bundle size significantly.", tags: %i[rails frontend productivity], created_at: 6.days.ago },
    { key: :stimulus, name: "Stimulus", url: "https://stimulus.hotwired.dev", desc: "Sprinkle-on JS framework from Basecamp. Minimal JavaScript that enhances HTML with behavior.", note: "Pairs well with Turbo. Perfect for progressive enhancement.", tags: %i[frontend productivity], created_at: 6.days.ago },
    { key: :postgres, name: "PostgreSQL", url: "https://www.postgresql.org", desc: "Battle-tested relational database with advanced features like JSON support, full-text search, and extensibility.", note: "Primary DB with pgvector. Excellent performance and reliability.", tags: %i[postgres backend], created_at: 12.days.ago },
    { key: :pgvector, name: "pgvector", url: "https://github.com/pgvector/pgvector", desc: "Vector embeddings inside Postgres. Enables semantic search and similarity queries without external services.", note: "Enables semantic search. Perfect for AI-powered features.", tags: %i[data backend], created_at: 10.days.ago },
    { key: :k8s, name: "Kubernetes", url: "https://kubernetes.io", desc: "Container orchestration platform for managing containerized applications at scale.", note: "Used for deployment simulations. Industry standard for container orchestration.", tags: %i[kubernetes devops], created_at: 14.days.ago },
    { key: :docker, name: "Docker", url: "https://www.docker.com", desc: "Container runtime and tooling. Package applications with dependencies for consistent deployments.", note: "Local dev environments. Essential for modern development workflows.", tags: %i[devops], created_at: 15.days.ago },
    { key: :gha, name: "GitHub Actions", url: "https://github.com/features/actions", desc: "GitHub-native CI/CD. Build, test, and deploy directly from your repository.", note: "Reusable workflows for checks. Integrates seamlessly with GitHub.", tags: %i[devops testing], created_at: 9.days.ago },
    { key: :prometheus, name: "Prometheus", url: "https://prometheus.io", desc: "Metrics and alerting toolkit. Time-series database for monitoring and alerting.", note: "Feeds Grafana dashboards. Industry standard for metrics collection.", tags: %i[observability devops], created_at: 11.days.ago },
    { key: :grafana, name: "Grafana", url: "https://grafana.com", desc: "Observability dashboards. Visualize metrics, logs, and traces from multiple sources.", note: "Pairs with Prometheus and Loki. Beautiful and powerful dashboards.", tags: %i[observability devops], created_at: 9.days.ago },
    { key: :langchain, name: "LangChain", url: "https://python.langchain.com", desc: "LLM orchestration library. Build applications with language models through composable chains.", note: "Used for agent experiments. Simplifies complex LLM workflows.", tags: %i[ai llm python], created_at: 7.days.ago },
    { key: :openai, name: "OpenAI API", url: "https://platform.openai.com", desc: "GPT models and embeddings. Access to state-of-the-art language models and embeddings.", note: "Default LLM provider. Reliable and well-documented API.", tags: %i[ai llm], created_at: 7.days.ago },
    { key: :pytest, name: "Pytest", url: "https://docs.pytest.org", desc: "Python testing framework. Simple, scalable, and feature-rich testing tool.", note: "Fast tests and fixtures. Excellent plugin ecosystem.", tags: %i[python testing], created_at: 5.days.ago },
    { key: :react, name: "React", url: "https://react.dev", desc: "Component-based UI library. Build interactive user interfaces with declarative components.", note: "Used for comparison to Hotwire. Industry standard for SPAs.", tags: %i[react frontend javascript], created_at: 16.days.ago },
    { key: :vite, name: "Vite", url: "https://vitejs.dev", desc: "Next generation frontend tooling. Lightning-fast HMR and optimized production builds.", note: "Fast HMR and optimized builds. Modern alternative to Webpack.", tags: %i[frontend javascript productivity], created_at: 4.days.ago },
    { key: :typescript, name: "TypeScript", url: "https://www.typescriptlang.org", desc: "Typed superset of JavaScript. Adds static type checking for better developer experience.", note: "Better DX with type safety. Catches errors at compile time.", tags: %i[javascript language], created_at: 13.days.ago },
    { key: :nextjs, name: "Next.js", url: "https://nextjs.org", desc: "React framework for production. Server-side rendering, static generation, and API routes.", note: "SSR, SSG, and API routes. Full-stack React framework.", tags: %i[react frontend framework], created_at: 11.days.ago },
    { key: :tailwind, name: "Tailwind CSS", url: "https://tailwindcss.com", desc: "Utility-first CSS framework. Rapidly build modern designs without leaving HTML.", note: "Rapid UI development. Highly customizable and performant.", tags: %i[frontend productivity], created_at: 7.days.ago },
    { key: :redis, name: "Redis", url: "https://redis.io", desc: "In-memory data structure store. Use as database, cache, message broker, and more.", note: "Caching and session storage. Extremely fast and versatile.", tags: %i[backend data], created_at: 10.days.ago },
    { key: :elasticsearch, name: "Elasticsearch", url: "https://www.elastic.co/elasticsearch", desc: "Distributed search and analytics engine. Powerful full-text search and real-time analytics.", note: "Full-text search and logging. Scales horizontally with ease.", tags: %i[data backend], created_at: 12.days.ago },
    { key: :terraform, name: "Terraform", url: "https://www.terraform.io", desc: "Infrastructure as code tool. Provision and manage cloud resources declaratively.", note: "Multi-cloud provisioning. Version control your infrastructure.", tags: %i[devops], created_at: 15.days.ago },
    { key: :ansible, name: "Ansible", url: "https://www.ansible.com", desc: "Configuration management automation. Agentless orchestration for servers and applications.", note: "Agentless orchestration. Simple YAML-based configuration.", tags: %i[devops], created_at: 13.days.ago },
    { key: :jenkins, name: "Jenkins", url: "https://www.jenkins.io", desc: "Automation server for CI/CD. Extensible with plugins for building, testing, and deploying.", note: "Extensible with plugins. Mature and battle-tested.", tags: %i[devops testing], created_at: 14.days.ago },
    { key: :sentry, name: "Sentry", url: "https://sentry.io", desc: "Error tracking and performance monitoring. Real-time error alerts with full stack traces.", note: "Real-time error alerts. Excellent for production debugging.", tags: %i[observability devops], created_at: 8.days.ago },
    { key: :datadog, name: "Datadog", url: "https://www.datadoghq.com", desc: "Monitoring and security platform. APM, logs, metrics, and security monitoring in one place.", note: "APM, logs, and metrics. Comprehensive observability solution.", tags: %i[observability devops], created_at: 6.days.ago },
    { key: :jupyter, name: "Jupyter", url: "https://jupyter.org", desc: "Interactive computing notebooks. Perfect for data science, ML experimentation, and visualization.", note: "Data science and ML workflows. Interactive and shareable notebooks.", tags: %i[data ai python], created_at: 9.days.ago },
    { key: :vue, name: "Vue.js", url: "https://vuejs.org", desc: "Progressive JavaScript framework. Approachable, versatile, and performant for building UIs.", note: "Great balance of simplicity and power. Excellent documentation.", tags: %i[vue frontend javascript], created_at: 10.days.ago },
    { key: :nuxt, name: "Nuxt.js", url: "https://nuxt.com", desc: "Vue meta-framework. Server-side rendering, static generation, and full-stack capabilities.", note: "Vue's answer to Next.js. Great DX and performance.", tags: %i[vue frontend framework], created_at: 9.days.ago },
    { key: :svelte, name: "Svelte", url: "https://svelte.dev", desc: "Compiler-based frontend framework. Write less code, ship smaller bundles.", note: "Compiles to vanilla JS. No runtime overhead.", tags: %i[svelte frontend javascript], created_at: 8.days.ago },
    { key: :sveltekit, name: "SvelteKit", url: "https://kit.svelte.dev", desc: "Svelte meta-framework. Full-stack framework with file-based routing and SSR.", note: "Modern framework with excellent performance. Great developer experience.", tags: %i[svelte frontend framework], created_at: 7.days.ago },
    { key: :fastapi, name: "FastAPI", url: "https://fastapi.tiangolo.com", desc: "Modern Python web framework. High performance with automatic API documentation.", note: "Fast and modern. Built on Starlette and Pydantic.", tags: %i[python backend framework], created_at: 6.days.ago },
    { key: :django, name: "Django", url: "https://www.djangoproject.com", desc: "High-level Python web framework. Batteries-included for rapid development.", note: "Mature and feature-rich. Excellent admin interface.", tags: %i[python backend framework], created_at: 11.days.ago },
    { key: :flask, name: "Flask", url: "https://flask.palletsprojects.com", desc: "Lightweight Python web framework. Minimal and flexible for building APIs.", note: "Simple and extensible. Great for microservices.", tags: %i[python backend framework], created_at: 10.days.ago },
    { key: :express, name: "Express.js", url: "https://expressjs.com", desc: "Minimal Node.js web framework. Fast and unopinionated for building APIs.", note: "Most popular Node.js framework. Huge ecosystem.", tags: %i[javascript backend framework], created_at: 12.days.ago },
    { key: :nestjs, name: "NestJS", url: "https://nestjs.com", desc: "Progressive Node.js framework. Built with TypeScript for scalable server-side applications.", note: "Enterprise-ready. Inspired by Angular architecture.", tags: %i[typescript backend framework], created_at: 9.days.ago },
    { key: :golang, name: "Go", url: "https://go.dev", desc: "Open source programming language. Simple, fast, and reliable for building software.", note: "Excellent concurrency. Great for microservices and CLI tools.", tags: %i[go backend language], created_at: 13.days.ago },
    { key: :rust, name: "Rust", url: "https://www.rust-lang.org", desc: "Systems programming language. Memory safety without garbage collection.", note: "Zero-cost abstractions. Perfect for performance-critical code.", tags: %i[rust backend language], created_at: 14.days.ago },
    { key: :mysql, name: "MySQL", url: "https://www.mysql.com", desc: "Popular relational database. Widely used for web applications.", note: "Mature and stable. Great for traditional applications.", tags: %i[mysql backend], created_at: 11.days.ago },
    { key: :mongodb, name: "MongoDB", url: "https://www.mongodb.com", desc: "NoSQL document database. Flexible schema for modern applications.", note: "Great for unstructured data. Horizontal scaling built-in.", tags: %i[mongodb backend data], created_at: 10.days.ago },
    { key: :sqlite, name: "SQLite", url: "https://www.sqlite.org", desc: "Embedded SQL database. Zero-configuration, serverless database engine.", note: "Perfect for local development and small apps. No server required.", tags: %i[sqlite backend], created_at: 9.days.ago },
    { key: :aws, name: "AWS", url: "https://aws.amazon.com", desc: "Amazon Web Services. Comprehensive cloud platform with 200+ services.", note: "Industry leader. Massive service catalog.", tags: %i[aws devops], created_at: 15.days.ago },
    { key: :gcp, name: "Google Cloud", url: "https://cloud.google.com", desc: "Google Cloud Platform. Scalable infrastructure and AI/ML services.", note: "Excellent for data and ML workloads. Great documentation.", tags: %i[google_cloud devops], created_at: 14.days.ago },
    { key: :azure, name: "Azure", url: "https://azure.microsoft.com", desc: "Microsoft Azure. Enterprise cloud platform with hybrid cloud capabilities.", note: "Great for Microsoft stack. Strong enterprise features.", tags: %i[azure devops], created_at: 13.days.ago },
    { key: :vercel, name: "Vercel", url: "https://vercel.com", desc: "Frontend cloud platform. Deploy Next.js and other frameworks with zero config.", note: "Perfect for JAMstack. Excellent DX and performance.", tags: %i[devops frontend], created_at: 5.days.ago },
    { key: :netlify, name: "Netlify", url: "https://www.netlify.com", desc: "JAMstack platform. Deploy static sites and serverless functions easily.", note: "Great for static sites. Built-in CI/CD and forms.", tags: %i[devops frontend], created_at: 6.days.ago },
    { key: :heroku, name: "Heroku", url: "https://www.heroku.com", desc: "Platform as a service. Deploy apps with git push simplicity.", note: "Developer-friendly. Perfect for prototypes and MVPs.", tags: %i[devops], created_at: 12.days.ago },
    { key: :circleci, name: "CircleCI", url: "https://circleci.com", desc: "CI/CD platform. Automate builds, tests, and deployments.", note: "Reliable and fast. Great for teams.", tags: %i[devops testing], created_at: 8.days.ago },
    { key: :gitlab_ci, name: "GitLab CI", url: "https://docs.gitlab.com/ee/ci", desc: "Built-in CI/CD for GitLab. Define pipelines in YAML.", note: "Integrated with GitLab. Free for open source.", tags: %i[devops testing], created_at: 9.days.ago },
    { key: :webpack, name: "Webpack", url: "https://webpack.js.org", desc: "Module bundler for JavaScript. Bundle assets for production.", note: "Industry standard. Highly configurable.", tags: %i[frontend javascript productivity], created_at: 13.days.ago },
    { key: :esbuild, name: "esbuild", url: "https://esbuild.github.io", desc: "Extremely fast JavaScript bundler. Written in Go for maximum performance.", note: "10-100x faster than Webpack. Great for large projects.", tags: %i[frontend javascript productivity], created_at: 4.days.ago },
    { key: :swc, name: "SWC", url: "https://swc.rs", desc: "Super-fast TypeScript/JavaScript compiler. Written in Rust.", note: "Drop-in replacement for Babel. Much faster.", tags: %i[frontend javascript productivity], created_at: 5.days.ago },
    { key: :babel, name: "Babel", url: "https://babeljs.io", desc: "JavaScript compiler. Transform modern JS to compatible versions.", note: "Industry standard. Huge plugin ecosystem.", tags: %i[frontend javascript productivity], created_at: 14.days.ago },
    { key: :jest, name: "Jest", url: "https://jestjs.io", desc: "JavaScript testing framework. Zero-config testing with great DX.", note: "Built-in mocking and coverage. Fast and reliable.", tags: %i[javascript testing], created_at: 7.days.ago },
    { key: :vitest, name: "Vitest", url: "https://vitest.dev", desc: "Fast unit test framework. Powered by Vite for speed.", note: "Jest-compatible API. Much faster execution.", tags: %i[javascript testing], created_at: 3.days.ago },
    { key: :playwright, name: "Playwright", url: "https://playwright.dev", desc: "End-to-end testing framework. Test across browsers and devices.", note: "Modern E2E testing. Great API and debugging tools.", tags: %i[testing javascript], created_at: 2.days.ago },
    { key: :cypress, name: "Cypress", url: "https://www.cypress.io", desc: "End-to-end testing framework. Time-travel debugging and real browser testing.", note: "Excellent DX. Great for component testing too.", tags: %i[testing javascript], created_at: 6.days.ago },
    { key: :storybook, name: "Storybook", url: "https://storybook.js.org", desc: "UI component development environment. Build and test components in isolation.", note: "Essential for component libraries. Great documentation tool.", tags: %i[frontend testing], created_at: 5.days.ago },
    { key: :eslint, name: "ESLint", url: "https://eslint.org", desc: "JavaScript linter. Find and fix problems in your code.", note: "Industry standard. Highly configurable rules.", tags: %i[javascript productivity], created_at: 12.days.ago },
    { key: :prettier, name: "Prettier", url: "https://prettier.io", desc: "Code formatter. Opinionated formatting for consistent code style.", note: "Zero configuration. Works with all languages.", tags: %i[productivity javascript], created_at: 11.days.ago },
    { key: :rubocop, name: "RuboCop", url: "https://rubocop.org", desc: "Ruby static code analyzer. Enforce style guide and best practices.", note: "Essential for Ruby teams. Highly configurable.", tags: %i[ruby productivity], created_at: 10.days.ago },
    { key: :black, name: "Black", url: "https://black.readthedocs.io", desc: "Python code formatter. Uncompromising code formatter for Python.", note: "Zero configuration. Consistent Python style.", tags: %i[python productivity], created_at: 9.days.ago },
    { key: :mypy, name: "mypy", url: "https://mypy.readthedocs.io", desc: "Static type checker for Python. Optional static typing for Python.", note: "Catch errors before runtime. Gradual typing support.", tags: %i[python productivity], created_at: 8.days.ago },
    { key: :graphql, name: "GraphQL", url: "https://graphql.org", desc: "Query language for APIs. Request exactly the data you need.", note: "Efficient data fetching. Strong typing and introspection.", tags: %i[apis backend], created_at: 11.days.ago },
    { key: :apollo, name: "Apollo", url: "https://www.apollographql.com", desc: "GraphQL platform. Tools for building GraphQL APIs and clients.", note: "Production-ready GraphQL. Great developer tools.", tags: %i[graphql backend], created_at: 10.days.ago },
    { key: :prisma, name: "Prisma", url: "https://www.prisma.io", desc: "Next-generation ORM. Type-safe database access for Node.js and TypeScript.", note: "Excellent DX. Auto-generated types and migrations.", tags: %i[backend typescript], created_at: 7.days.ago },
    { key: :sequelize, name: "Sequelize", url: "https://sequelize.org", desc: "Node.js ORM. Promise-based ORM for Postgres, MySQL, and more.", note: "Mature and feature-rich. Great for complex queries.", tags: %i[backend javascript], created_at: 12.days.ago },
    { key: :typeorm, name: "TypeORM", url: "https://typeorm.io", desc: "TypeScript ORM. Works with TypeScript and JavaScript.", note: "Decorator-based. Great for NestJS projects.", tags: %i[backend typescript], created_at: 9.days.ago },
    { key: :supabase, name: "Supabase", url: "https://supabase.com", desc: "Open source Firebase alternative. PostgreSQL with real-time and auth.", note: "Great for rapid prototyping. Built on Postgres.", tags: %i[backend data], created_at: 4.days.ago },
    { key: :firebase, name: "Firebase", url: "https://firebase.google.com", desc: "Google's app development platform. Backend services for mobile and web.", note: "Rapid development. Great for MVPs and prototypes.", tags: %i[backend devops], created_at: 13.days.ago },
    { key: :stripe, name: "Stripe", url: "https://stripe.com", desc: "Payment processing platform. Accept payments online and in mobile apps.", note: "Developer-friendly API. Excellent documentation.", tags: %i[backend], created_at: 11.days.ago },
    { key: :twilio, name: "Twilio", url: "https://www.twilio.com", desc: "Cloud communications platform. SMS, voice, video, and more.", note: "Reliable messaging. Great API design.", tags: %i[backend], created_at: 10.days.ago },
    { key: :sendgrid, name: "SendGrid", url: "https://sendgrid.com", desc: "Email delivery service. Transactional and marketing emails at scale.", note: "Reliable email delivery. Great analytics.", tags: %i[backend], created_at: 9.days.ago },
    { key: :auth0, name: "Auth0", url: "https://auth0.com", desc: "Identity and access management. Authentication and authorization as a service.", note: "Enterprise-ready auth. Supports many identity providers.", tags: %i[backend security], created_at: 8.days.ago },
    { key: :okta, name: "Okta", url: "https://www.okta.com", desc: "Identity management platform. Single sign-on and user management.", note: "Enterprise identity. Great for large organizations.", tags: %i[backend security], created_at: 7.days.ago },
    { key: :n8n, name: "n8n", url: "https://n8n.io", desc: "Workflow automation tool. Visual workflow builder for integrations.", note: "Open source alternative to Zapier. Self-hostable.", tags: %i[productivity backend], created_at: 6.days.ago },
    { key: :zapier, name: "Zapier", url: "https://zapier.com", desc: "Workflow automation platform. Connect apps and automate workflows.", note: "Huge app ecosystem. No-code automation.", tags: %i[productivity backend], created_at: 12.days.ago },
    { key: :airtable, name: "Airtable", url: "https://www.airtable.com", desc: "Cloud collaboration platform. Spreadsheet-database hybrid with API.", note: "Great for non-technical users. Powerful API.", tags: %i[productivity data], created_at: 11.days.ago },
    { key: :notion, name: "Notion", url: "https://www.notion.so", desc: "All-in-one workspace. Notes, docs, databases, and collaboration.", note: "Versatile tool. Great for documentation and wikis.", tags: %i[productivity], created_at: 10.days.ago },
    { key: :linear, name: "Linear", url: "https://linear.app", desc: "Issue tracking and project management. Built for modern software teams.", note: "Beautiful and fast. Great keyboard shortcuts.", tags: %i[productivity], created_at: 5.days.ago },
    { key: :github, name: "GitHub", url: "https://github.com", desc: "Code hosting platform. Git repository hosting with collaboration features.", note: "Industry standard. Great for open source.", tags: %i[devops productivity], created_at: 15.days.ago },
    { key: :gitlab, name: "GitLab", url: "https://about.gitlab.com", desc: "DevOps platform. Complete CI/CD and collaboration in one tool.", note: "All-in-one solution. Great for self-hosting.", tags: %i[devops productivity], created_at: 14.days.ago },
    { key: :bitbucket, name: "Bitbucket", url: "https://bitbucket.org", desc: "Git repository hosting. Free private repos and CI/CD.", note: "Great for small teams. Integrates with Jira.", tags: %i[devops productivity], created_at: 13.days.ago }
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
      desc: "Comprehensive guide to distributed systems covering consistency models, availability patterns, and partition tolerance strategies. Deep dive into CAP theorem with real-world examples.",
      note: "CAP theorem and practical trade-offs. Essential reading for architects.",
      type: :article,
      status: :completed,
      tools: %i[k8s],
      tags: %i[backend devops],
      created_at: 18.days.ago
    },
    {
      key: :vue_composition_api,
      user: :charlie,
      name: "Vue 3 Composition API deep dive",
      url: "https://example.com/vue-composition-api",
      desc: "Complete guide to Vue 3's Composition API. Learn how to build reusable logic with composables and improve code organization.",
      note: "Covers reactivity, lifecycle hooks, and best practices. Great for React developers.",
      type: :article,
      status: :completed,
      tools: %i[vue],
      tags: %i[frontend javascript],
      created_at: 1.day.ago
    },
    {
      key: :nuxt_ssr_performance,
      user: :charlie,
      name: "Optimizing Nuxt.js SSR performance",
      url: "https://example.com/nuxt-ssr-performance",
      desc: "Performance optimization techniques for Nuxt.js server-side rendering. Covers code splitting, caching strategies, and bundle optimization.",
      note: "Real-world benchmarks and optimization tips. Improved our TTFB by 40%.",
      type: :guide,
      status: :completed,
      tools: %i[nuxt vue],
      tags: %i[frontend performance],
      created_at: 2.days.ago
    },
    {
      key: :svelte_reactive_patterns,
      user: :charlie,
      name: "Svelte reactive patterns and stores",
      url: "https://example.com/svelte-reactive",
      desc: "Understanding Svelte's reactivity system and how to use stores effectively for state management across components.",
      note: "Covers writable, readable, and derived stores. Simple and powerful.",
      type: :article,
      status: :completed,
      tools: %i[svelte],
      tags: %i[frontend javascript],
      created_at: 3.days.ago
    },
    {
      key: :sveltekit_routing,
      user: :charlie,
      name: "SvelteKit file-based routing guide",
      url: "https://example.com/sveltekit-routing",
      desc: "Complete guide to SvelteKit's file-based routing system. Learn about layouts, load functions, and form actions.",
      note: "Much simpler than React Router. Great developer experience.",
      type: :guide,
      status: :completed,
      tools: %i[sveltekit svelte],
      tags: %i[frontend framework],
      created_at: 4.days.ago
    },
    {
      key: :fastapi_async,
      user: :diana,
      name: "Building async APIs with FastAPI",
      url: "https://example.com/fastapi-async",
      desc: "Leverage Python's async/await with FastAPI for high-performance APIs. Covers database connections, background tasks, and WebSockets.",
      note: "Excellent performance with async. Great for I/O-bound operations.",
      type: :article,
      status: :completed,
      tools: %i[fastapi python],
      tags: %i[backend python],
      created_at: 1.day.ago
    },
    {
      key: :django_orm_optimization,
      user: :diana,
      name: "Django ORM query optimization",
      url: "https://example.com/django-orm-optimization",
      desc: "Advanced Django ORM techniques to avoid N+1 queries and improve database performance. Covers select_related, prefetch_related, and annotations.",
      note: "Essential for scaling Django apps. Reduced query count by 90%.",
      type: :article,
      status: :completed,
      tools: %i[django python],
      tags: %i[backend performance],
      created_at: 2.days.ago
    },
    {
      key: :flask_blueprints,
      user: :diana,
      name: "Organizing Flask apps with blueprints",
      url: "https://example.com/flask-blueprints",
      desc: "How to structure large Flask applications using blueprints for modularity and maintainability.",
      note: "Great for microservices architecture. Keeps code organized.",
      type: :guide,
      status: :completed,
      tools: %i[flask python],
      tags: %i[backend framework],
      created_at: 3.days.ago
    },
    {
      key: :express_middleware,
      user: :henry,
      name: "Express.js middleware patterns",
      url: "https://example.com/express-middleware",
      desc: "Building reusable Express.js middleware for authentication, logging, error handling, and request validation.",
      note: "Middleware is the heart of Express. Learn to compose them effectively.",
      type: :article,
      status: :completed,
      tools: %i[express javascript],
      tags: %i[backend javascript],
      created_at: 4.days.ago
    },
    {
      key: :nestjs_dependency_injection,
      user: :henry,
      name: "NestJS dependency injection explained",
      url: "https://example.com/nestjs-di",
      desc: "Understanding NestJS dependency injection system. Learn about providers, modules, and custom decorators.",
      note: "Powerful DI system inspired by Angular. Great for enterprise apps.",
      type: :guide,
      status: :completed,
      tools: %i[nestjs typescript],
      tags: %i[backend framework],
      created_at: 5.days.ago
    },
    {
      key: :golang_concurrency,
      user: :henry,
      name: "Go concurrency patterns",
      url: "https://example.com/golang-concurrency",
      desc: "Master Go's goroutines and channels for concurrent programming. Covers worker pools, fan-out/fan-in, and context cancellation.",
      note: "Go's concurrency model is elegant. Essential for high-performance services.",
      type: :article,
      status: :completed,
      tools: %i[golang],
      tags: %i[backend language],
      created_at: 6.days.ago
    },
    {
      key: :rust_ownership,
      user: :henry,
      name: "Understanding Rust ownership",
      url: "https://example.com/rust-ownership",
      desc: "Deep dive into Rust's ownership system, borrowing, and lifetimes. Learn how Rust ensures memory safety without garbage collection.",
      note: "The borrow checker is your friend. Once you understand it, Rust becomes powerful.",
      type: :article,
      status: :completed,
      tools: %i[rust],
      tags: %i[backend language],
      created_at: 7.days.ago
    },
    {
      key: :mysql_indexing,
      user: :henry,
      name: "MySQL indexing strategies",
      url: "https://example.com/mysql-indexing",
      desc: "How to design effective indexes in MySQL. Covers B-tree indexes, composite indexes, and covering indexes for query optimization.",
      note: "Proper indexing can improve query performance by orders of magnitude.",
      type: :guide,
      status: :completed,
      tools: %i[mysql],
      tags: %i[backend performance],
      created_at: 8.days.ago
    },
    {
      key: :mongodb_aggregation,
      user: :diana,
      name: "MongoDB aggregation pipeline",
      url: "https://example.com/mongodb-aggregation",
      desc: "Master MongoDB's aggregation framework for complex data transformations and analytics. Covers stages, operators, and performance tips.",
      note: "Aggregation pipeline is powerful for data analysis. Great for reporting.",
      type: :article,
      status: :completed,
      tools: %i[mongodb],
      tags: %i[backend data],
      created_at: 9.days.ago
    },
    {
      key: :aws_lambda_cold_starts,
      user: :bob,
      name: "Optimizing AWS Lambda cold starts",
      url: "https://example.com/aws-lambda-cold-starts",
      desc: "Strategies to reduce AWS Lambda cold start times. Covers provisioned concurrency, layer optimization, and runtime selection.",
      note: "Cold starts can kill user experience. These techniques help significantly.",
      type: :article,
      status: :completed,
      tools: %i[aws],
      tags: %i[devops performance],
      created_at: 1.day.ago
    },
    {
      key: :gcp_cloud_run,
      user: :bob,
      name: "Deploying containers to Cloud Run",
      url: "https://example.com/gcp-cloud-run",
      desc: "Complete guide to deploying containerized applications on Google Cloud Run. Covers scaling, environment variables, and custom domains.",
      note: "Serverless containers are the future. Great pricing model.",
      type: :guide,
      status: :completed,
      tools: %i[gcp],
      tags: %i[devops],
      created_at: 2.days.ago
    },
    {
      key: :azure_functions,
      user: :bob,
      name: "Building serverless functions on Azure",
      url: "https://example.com/azure-functions",
      desc: "Getting started with Azure Functions for event-driven serverless applications. Covers triggers, bindings, and deployment.",
      note: "Great for microservices. Integrates well with Azure services.",
      type: :guide,
      status: :completed,
      tools: %i[azure],
      tags: %i[devops],
      created_at: 3.days.ago
    },
    {
      key: :vercel_edge_functions,
      user: :charlie,
      name: "Vercel Edge Functions tutorial",
      url: "https://example.com/vercel-edge-functions",
      desc: "Building edge functions with Vercel for global low-latency API routes. Learn about edge runtime limitations and use cases.",
      note: "Edge functions run close to users. Perfect for personalization and A/B testing.",
      type: :guide,
      status: :completed,
      tools: %i[vercel],
      tags: %i[devops frontend],
      created_at: 1.day.ago
    },
    {
      key: :netlify_functions,
      user: :charlie,
      name: "Netlify Functions for JAMstack",
      url: "https://example.com/netlify-functions",
      desc: "Building serverless functions with Netlify. Learn how to create API endpoints, handle forms, and integrate with external services.",
      note: "Perfect for static sites that need dynamic functionality. Zero config deployment.",
      type: :guide,
      status: :completed,
      tools: %i[netlify],
      tags: %i[devops frontend],
      created_at: 2.days.ago
    },
    {
      key: :heroku_dynos,
      user: :bob,
      name: "Heroku dyno types and scaling",
      url: "https://example.com/heroku-dynos",
      desc: "Understanding Heroku dyno types, scaling strategies, and cost optimization. Covers web dynos, worker dynos, and one-off dynos.",
      note: "Heroku makes deployment easy. Learn to scale efficiently.",
      type: :article,
      status: :completed,
      tools: %i[heroku],
      tags: %i[devops],
      created_at: 4.days.ago
    },
    {
      key: :circleci_workflows,
      user: :jack,
      name: "CircleCI workflow orchestration",
      url: "https://example.com/circleci-workflows",
      desc: "Advanced CircleCI workflows for complex CI/CD pipelines. Learn about job dependencies, parallelism, and conditional execution.",
      note: "Workflows make complex pipelines manageable. Great for monorepos.",
      type: :guide,
      status: :completed,
      tools: %i[circleci],
      tags: %i[devops testing],
      created_at: 1.day.ago
    },
    {
      key: :gitlab_ci_variables,
      user: :jack,
      name: "GitLab CI variables and secrets",
      url: "https://example.com/gitlab-ci-variables",
      desc: "Managing environment variables, secrets, and configuration in GitLab CI. Covers protected variables, masked variables, and file variables.",
      note: "Proper secret management is crucial. GitLab CI makes it easy.",
      type: :guide,
      status: :completed,
      tools: %i[gitlab_ci],
      tags: %i[devops testing],
      created_at: 2.days.ago
    },
    {
      key: :webpack_code_splitting,
      user: :charlie,
      name: "Webpack code splitting strategies",
      url: "https://example.com/webpack-code-splitting",
      desc: "Advanced code splitting techniques with Webpack. Learn about dynamic imports, chunk optimization, and lazy loading.",
      note: "Code splitting is essential for large apps. Webpack makes it powerful.",
      type: :article,
      status: :completed,
      tools: %i[webpack],
      tags: %i[frontend productivity],
      created_at: 3.days.ago
    },
    {
      key: :esbuild_config,
      user: :charlie,
      name: "Configuring esbuild for production",
      url: "https://example.com/esbuild-config",
      desc: "Production-ready esbuild configuration. Covers minification, source maps, tree shaking, and plugin development.",
      note: "esbuild is incredibly fast. Great replacement for Webpack in many cases.",
      type: :guide,
      status: :completed,
      tools: %i[esbuild],
      tags: %i[frontend productivity],
      created_at: 4.days.ago
    },
    {
      key: :swc_rust_compiler,
      user: :charlie,
      name: "Using SWC as Babel replacement",
      url: "https://example.com/swc-babel-replacement",
      desc: "Migrating from Babel to SWC for faster JavaScript/TypeScript compilation. Covers plugin compatibility and configuration.",
      note: "SWC is 20x faster than Babel. Drop-in replacement for most use cases.",
      type: :guide,
      status: :completed,
      tools: %i[swc],
      tags: %i[frontend productivity],
      created_at: 5.days.ago
    },
    {
      key: :jest_mocking,
      user: :jack,
      name: "Jest mocking patterns",
      url: "https://example.com/jest-mocking",
      desc: "Comprehensive guide to mocking in Jest. Learn about jest.fn(), jest.mock(), and manual mocks for testing complex dependencies.",
      note: "Mocking is essential for unit tests. Jest makes it straightforward.",
      type: :article,
      status: :completed,
      tools: %i[jest],
      tags: %i[javascript testing],
      created_at: 1.day.ago
    },
    {
      key: :vitest_vs_jest,
      user: :jack,
      name: "Vitest vs Jest comparison",
      url: "https://example.com/vitest-vs-jest",
      desc: "Detailed comparison between Vitest and Jest. Performance benchmarks, feature differences, and migration guide.",
      note: "Vitest is faster and has better ESM support. Great for Vite projects.",
      type: :article,
      status: :completed,
      tools: %i[vitest jest],
      tags: %i[javascript testing],
      created_at: 2.days.ago
    },
    {
      key: :playwright_automation,
      user: :jack,
      name: "End-to-end testing with Playwright",
      url: "https://example.com/playwright-automation",
      desc: "Complete Playwright tutorial for E2E testing. Covers page objects, fixtures, parallel execution, and CI/CD integration.",
      note: "Playwright is the future of E2E testing. Excellent API and debugging tools.",
      type: :guide,
      status: :completed,
      tools: %i[playwright],
      tags: %i[testing javascript],
      created_at: 3.days.ago
    },
    {
      key: :cypress_component_testing,
      user: :jack,
      name: "Component testing with Cypress",
      url: "https://example.com/cypress-component-testing",
      desc: "Using Cypress for component testing in React, Vue, and Angular. Learn about mounting, interactions, and assertions.",
      note: "Cypress component testing is powerful. Great alternative to Storybook for testing.",
      type: :guide,
      status: :completed,
      tools: %i[cypress],
      tags: %i[testing javascript],
      created_at: 4.days.ago
    },
    {
      key: :storybook_addons,
      user: :ivy,
      name: "Essential Storybook addons",
      url: "https://example.com/storybook-addons",
      desc: "Must-have Storybook addons for component development. Covers accessibility, viewport, controls, and documentation addons.",
      note: "Addons make Storybook powerful. Essential for component libraries.",
      type: :article,
      status: :completed,
      tools: %i[storybook],
      tags: %i[frontend testing],
      created_at: 1.day.ago
    },
    {
      key: :eslint_rules,
      user: :charlie,
      name: "Custom ESLint rules",
      url: "https://example.com/eslint-rules",
      desc: "Creating custom ESLint rules for project-specific code standards. Learn about AST traversal and rule development.",
      note: "Custom rules enforce team conventions. Great for large codebases.",
      type: :article,
      status: :completed,
      tools: %i[eslint],
      tags: %i[javascript productivity],
      created_at: 2.days.ago
    },
    {
      key: :prettier_integration,
      user: :charlie,
      name: "Integrating Prettier with ESLint",
      url: "https://example.com/prettier-eslint",
      desc: "Setting up Prettier with ESLint for consistent code formatting. Covers eslint-config-prettier and editor integration.",
      note: "Prettier + ESLint is the standard setup. Eliminates formatting debates.",
      type: :guide,
      status: :completed,
      tools: %i[prettier eslint],
      tags: %i[productivity javascript],
      created_at: 3.days.ago
    },
    {
      key: :rubocop_config,
      user: :alice,
      name: "RuboCop configuration best practices",
      url: "https://example.com/rubocop-config",
      desc: "Configuring RuboCop for Ruby projects. Learn about cops, inheritance, and disabling rules appropriately.",
      note: "RuboCop keeps Ruby code consistent. Essential for team projects.",
      type: :guide,
      status: :completed,
      tools: %i[rubocop],
      tags: %i[ruby productivity],
      created_at: 4.days.ago
    },
    {
      key: :black_formatting,
      user: :diana,
      name: "Black code formatter setup",
      url: "https://example.com/black-formatting",
      desc: "Setting up Black for automatic Python code formatting. Covers configuration, editor integration, and pre-commit hooks.",
      note: "Black eliminates style debates. Zero configuration needed.",
      type: :guide,
      status: :completed,
      tools: %i[black],
      tags: %i[python productivity],
      created_at: 5.days.ago
    },
    {
      key: :mypy_gradual_typing,
      user: :diana,
      name: "Gradual typing with mypy",
      url: "https://example.com/mypy-gradual-typing",
      desc: "Adding type hints to existing Python codebases with mypy. Learn about gradual typing strategies and common patterns.",
      note: "Gradual typing makes Python safer. mypy catches bugs early.",
      type: :article,
      status: :completed,
      tools: %i[mypy],
      tags: %i[python productivity],
      created_at: 6.days.ago
    },
    {
      key: :graphql_schema_design,
      user: :henry,
      name: "GraphQL schema design patterns",
      url: "https://example.com/graphql-schema",
      desc: "Best practices for designing GraphQL schemas. Covers types, interfaces, unions, and schema evolution strategies.",
      note: "Good schema design is crucial. GraphQL's type system is powerful.",
      type: :article,
      status: :completed,
      tools: %i[graphql],
      tags: %i[apis backend],
      created_at: 1.day.ago
    },
    {
      key: :apollo_server_setup,
      user: :henry,
      name: "Setting up Apollo Server",
      url: "https://example.com/apollo-server",
      desc: "Complete guide to Apollo Server for building GraphQL APIs. Covers resolvers, data sources, and subscriptions.",
      note: "Apollo Server is production-ready. Great developer experience.",
      type: :guide,
      status: :completed,
      tools: %i[apollo graphql],
      tags: %i[graphql backend],
      created_at: 2.days.ago
    },
    {
      key: :prisma_migrations,
      user: :henry,
      name: "Prisma migrations workflow",
      url: "https://example.com/prisma-migrations",
      desc: "Managing database migrations with Prisma. Learn about schema changes, migration files, and deployment strategies.",
      note: "Prisma migrations are type-safe. Great for TypeScript projects.",
      type: :guide,
      status: :completed,
      tools: %i[prisma],
      tags: %i[backend typescript],
      created_at: 3.days.ago
    },
    {
      key: :sequelize_associations,
      user: :henry,
      name: "Sequelize associations and queries",
      url: "https://example.com/sequelize-associations",
      desc: "Mastering Sequelize associations for complex data relationships. Covers hasMany, belongsTo, and many-to-many relationships.",
      note: "Associations make Sequelize powerful. Learn to use them effectively.",
      type: :article,
      status: :completed,
      tools: %i[sequelize],
      tags: %i[backend javascript],
      created_at: 4.days.ago
    },
    {
      key: :typeorm_entities,
      user: :henry,
      name: "TypeORM entities and decorators",
      url: "https://example.com/typeorm-entities",
      desc: "Building TypeORM entities with decorators. Learn about columns, relations, and entity inheritance.",
      note: "TypeORM's decorator syntax is clean. Great for NestJS projects.",
      type: :guide,
      status: :completed,
      tools: %i[typeorm],
      tags: %i[backend typescript],
      created_at: 5.days.ago
    },
    {
      key: :supabase_realtime,
      user: :alice,
      name: "Supabase real-time subscriptions",
      url: "https://example.com/supabase-realtime",
      desc: "Using Supabase real-time features for live data updates. Learn about PostgreSQL replication and WebSocket connections.",
      note: "Real-time is built-in with Supabase. Great for collaborative features.",
      type: :guide,
      status: :completed,
      tools: %i[supabase],
      tags: %i[backend data],
      created_at: 1.day.ago
    },
    {
      key: :firebase_functions,
      user: :alice,
      name: "Firebase Cloud Functions",
      url: "https://example.com/firebase-functions",
      desc: "Building serverless functions with Firebase. Covers HTTP functions, background functions, and scheduled functions.",
      note: "Firebase Functions integrate seamlessly. Great for mobile apps.",
      type: :guide,
      status: :completed,
      tools: %i[firebase],
      tags: %i[backend devops],
      created_at: 2.days.ago
    },
    {
      key: :stripe_webhooks,
      user: :henry,
      name: "Stripe webhook handling",
      url: "https://example.com/stripe-webhooks",
      desc: "Implementing secure Stripe webhook handlers. Learn about event verification, idempotency, and error handling.",
      note: "Webhooks are crucial for payment flows. Stripe makes it secure.",
      type: :guide,
      status: :completed,
      tools: %i[stripe],
      tags: %i[backend],
      created_at: 3.days.ago
    },
    {
      key: :twilio_voice_api,
      user: :henry,
      name: "Building voice apps with Twilio",
      url: "https://example.com/twilio-voice",
      desc: "Creating voice applications with Twilio Voice API. Covers call routing, IVR, and call recording.",
      note: "Twilio Voice API is powerful. Great for customer service apps.",
      type: :guide,
      status: :completed,
      tools: %i[twilio],
      tags: %i[backend],
      created_at: 4.days.ago
    },
    {
      key: :sendgrid_templates,
      user: :henry,
      name: "SendGrid email templates",
      url: "https://example.com/sendgrid-templates",
      desc: "Creating and managing email templates with SendGrid. Learn about dynamic templates, personalization, and A/B testing.",
      note: "Templates make email campaigns manageable. SendGrid's editor is great.",
      type: :guide,
      status: :completed,
      tools: %i[sendgrid],
      tags: %i[backend],
      created_at: 5.days.ago
    },
    {
      key: :auth0_integration,
      user: :eve,
      name: "Auth0 integration guide",
      url: "https://example.com/auth0-integration",
      desc: "Integrating Auth0 for authentication and authorization. Covers social logins, JWT tokens, and role-based access control.",
      note: "Auth0 handles auth complexity. Great for enterprise apps.",
      type: :guide,
      status: :completed,
      tools: %i[auth0],
      tags: %i[backend security],
      created_at: 1.day.ago
    },
    {
      key: :okta_sso,
      user: :eve,
      name: "Okta single sign-on setup",
      url: "https://example.com/okta-sso",
      desc: "Configuring Okta for enterprise single sign-on. Learn about SAML, OIDC, and user provisioning.",
      note: "Okta is enterprise-grade. Perfect for large organizations.",
      type: :guide,
      status: :completed,
      tools: %i[okta],
      tags: %i[backend security],
      created_at: 2.days.ago
    },
    {
      key: :n8n_workflows,
      user: :frank,
      name: "Building workflows with n8n",
      url: "https://example.com/n8n-workflows",
      desc: "Creating automation workflows with n8n. Learn about nodes, expressions, and error handling.",
      note: "n8n is open source and powerful. Great alternative to Zapier.",
      type: :guide,
      status: :completed,
      tools: %i[n8n],
      tags: %i[productivity backend],
      created_at: 3.days.ago
    },
    {
      key: :zapier_zaps,
      user: :frank,
      name: "Zapier automation patterns",
      url: "https://example.com/zapier-zaps",
      desc: "Common Zapier automation patterns for connecting apps. Covers triggers, actions, and filters.",
      note: "Zapier has huge app ecosystem. Great for non-technical users.",
      type: :article,
      status: :completed,
      tools: %i[zapier],
      tags: %i[productivity backend],
      created_at: 4.days.ago
    },
    {
      key: :airtable_api,
      user: :frank,
      name: "Airtable API integration",
      url: "https://example.com/airtable-api",
      desc: "Using Airtable as a backend with their REST API. Learn about bases, tables, and record operations.",
      note: "Airtable is great for rapid prototyping. Powerful API for custom apps.",
      type: :guide,
      status: :completed,
      tools: %i[airtable],
      tags: %i[productivity data],
      created_at: 5.days.ago
    },
    {
      key: :notion_api,
      user: :frank,
      name: "Notion API for automation",
      url: "https://example.com/notion-api",
      desc: "Automating Notion with their API. Learn about pages, databases, and blocks manipulation.",
      note: "Notion API is powerful. Great for building custom integrations.",
      type: :guide,
      status: :completed,
      tools: %i[notion],
      tags: %i[productivity],
      created_at: 6.days.ago
    },
    {
      key: :linear_api,
      user: :frank,
      name: "Linear API for project management",
      url: "https://example.com/linear-api",
      desc: "Using Linear's API for custom project management workflows. Covers issues, projects, and teams.",
      note: "Linear's API is well-designed. Great for building custom dashboards.",
      type: :guide,
      status: :completed,
      tools: %i[linear],
      tags: %i[productivity],
      created_at: 7.days.ago
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
    { key: :rails_stack, user: :alice, name: "Rails & Hotwire Stack", visibility: :public, tools: %i[rails turbo stimulus postgres rubocop], submissions: %i[hotwire_dashboard gha_ci rubocop_config] },
    { key: :platform_ops, user: :bob, name: "Platform Ops", visibility: :public, tools: %i[docker k8s gha terraform aws ansible], submissions: %i[k8s_deploy observability_stack terraform_aws ansible_playbooks aws_lambda_cold_starts] },
    { key: :ai_retrieval, user: :diana, name: "AI Retrieval Recipes", visibility: :public, tools: %i[langchain pgvector openai jupyter fastapi], submissions: %i[pgvector_search langchain_agents fastapi_async] },
    { key: :frontend_choices, user: :charlie, name: "Frontend Choices", visibility: :public, tools: %i[react turbo stimulus vite nextjs typescript vue svelte], submissions: %i[react_vs_turbo vite_setup nextjs_ssr typescript_advanced vue_composition_api] },
    { key: :security_watch, user: :eve, name: "Security & Reliability", visibility: :private, tools: %i[gha prometheus grafana sentry auth0], submissions: %i[observability_stack auth0_integration okta_sso] },
    { key: :archived, user: :ghost, name: "Archived Picks", visibility: :private, tools: %i[react], submissions: [] },
    { key: :testing_tools, user: :jack, name: "Testing Tools", visibility: :public, tools: %i[jest vitest playwright cypress pytest], submissions: %i[jest_mocking vitest_vs_jest playwright_automation cypress_component_testing pytest_patterns] },
    { key: :backend_frameworks, user: :henry, name: "Backend Frameworks", visibility: :public, tools: %i[rails django fastapi express nestjs golang rust], submissions: %i[express_middleware nestjs_dependency_injection golang_concurrency rust_ownership] },
    { key: :databases, user: :henry, name: "Database Tools", visibility: :public, tools: %i[postgres mysql mongodb redis elasticsearch], submissions: %i[redis_caching elasticsearch_search mysql_indexing mongodb_aggregation] },
    { key: :ml_stack, user: :kate, name: "ML & Data Science", visibility: :public, tools: %i[jupyter python langchain openai pgvector], submissions: %i[jupyter_notebooks ml_pipelines langchain_agents pgvector_search] },
    { key: :observability, user: :liam, name: "Observability Stack", visibility: :public, tools: %i[prometheus grafana sentry datadog elasticsearch], submissions: %i[observability_stack sentry_integration datadog_dashboards] },
    { key: :frontend_ui, user: :ivy, name: "Frontend UI Tools", visibility: :public, tools: %i[tailwind react storybook vite], submissions: %i[tailwind_components storybook_addons vite_setup] },
    { key: :productivity, user: :frank, name: "Productivity Tools", visibility: :public, tools: %i[linear notion airtable zapier n8n github], submissions: %i[linear_api notion_api airtable_api zapier_zaps n8n_workflows] },
    { key: :cloud_platforms, user: :bob, name: "Cloud Platforms", visibility: :public, tools: %i[aws gcp azure vercel netlify heroku], submissions: %i[aws_lambda_cold_starts gcp_cloud_run azure_functions vercel_edge_functions netlify_functions heroku_dynos] },
    { key: :ci_cd, user: :jack, name: "CI/CD Tools", visibility: :public, tools: %i[gha circleci gitlab_ci jenkins], submissions: %i[gha_ci circleci_workflows gitlab_ci_variables jenkins_pipelines] },
    { key: :code_quality, user: :charlie, name: "Code Quality Tools", visibility: :public, tools: %i[eslint prettier rubocop black mypy], submissions: %i[eslint_rules prettier_integration rubocop_config black_formatting mypy_gradual_typing] },
    { key: :api_tools, user: :henry, name: "API Development", visibility: :public, tools: %i[graphql apollo prisma sequelize typeorm], submissions: %i[graphql_schema_design apollo_server_setup prisma_migrations sequelize_associations typeorm_entities] },
    { key: :payment_apis, user: :henry, name: "Payment & Communication APIs", visibility: :public, tools: %i[stripe twilio sendgrid], submissions: %i[stripe_webhooks twilio_voice_api sendgrid_templates] },
    { key: :frontend_build, user: :charlie, name: "Frontend Build Tools", visibility: :public, tools: %i[webpack esbuild swc vite babel], submissions: %i[webpack_code_splitting esbuild_config swc_rust_compiler vite_setup] },
    { key: :python_stack, user: :diana, name: "Python Development Stack", visibility: :public, tools: %i[python django fastapi flask pytest black mypy], submissions: %i[fastapi_async django_orm_optimization flask_blueprints pytest_patterns black_formatting mypy_gradual_typing] },
    { key: :javascript_ecosystem, user: :charlie, name: "JavaScript Ecosystem", visibility: :public, tools: %i[javascript typescript react vue svelte nextjs], submissions: %i[typescript_advanced vue_composition_api svelte_reactive_patterns nextjs_ssr] },
    { key: :devops_infra, user: :bob, name: "DevOps & Infrastructure", visibility: :public, tools: %i[terraform ansible docker k8s aws], submissions: %i[terraform_aws ansible_playbooks k8s_deploy aws_lambda_cold_starts] },
    { key: :mobile_dev, user: :grace, name: "Mobile Development", visibility: :public, tools: %i[react nextjs typescript], submissions: %i[react_native_setup nextjs_ssr typescript_advanced] },
    { key: :architecture, user: :mia, name: "System Architecture", visibility: :public, tools: %i[golang rust k8s graphql], submissions: %i[microservices_architecture distributed_systems api_design graphql_schema_design] },
    { key: :monitoring, user: :liam, name: "Monitoring & Alerting", visibility: :public, tools: %i[prometheus grafana sentry datadog], submissions: %i[observability_stack sentry_integration datadog_dashboards] }
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
    # Core interactions (existing ones with better variety)
    { user: :alice, tool: :rails, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :alice, tool: :turbo, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :alice, tool: :stimulus, upvote: true, read_at: 3.days.ago },
    { user: :alice, tool: :postgres, upvote: true, favorite: true, read_at: 6.days.ago },
    { user: :alice, tool: :rubocop, upvote: true, read_at: 2.days.ago },
    { user: :alice, tool: :github, upvote: true, read_at: 1.day.ago },
    { user: :bob, tool: :docker, upvote: true, favorite: true, read_at: 7.days.ago },
    { user: :bob, tool: :k8s, upvote: true, favorite: true, read_at: 6.days.ago },
    { user: :bob, tool: :gha, upvote: true, read_at: 5.days.ago },
    { user: :bob, tool: :terraform, upvote: true, favorite: true, read_at: 8.days.ago },
    { user: :bob, tool: :ansible, upvote: true, read_at: 7.days.ago },
    { user: :bob, tool: :aws, upvote: true, read_at: 6.days.ago },
    { user: :bob, tool: :gcp, upvote: true, read_at: 5.days.ago },
    { user: :bob, tool: :azure, upvote: true, read_at: 4.days.ago },
    { user: :charlie, tool: :react, upvote: true, favorite: true, read_at: 6.days.ago },
    { user: :charlie, tool: :turbo, upvote: true, read_at: 2.days.ago },
    { user: :charlie, tool: :vite, upvote: true, favorite: true, read_at: 1.day.ago },
    { user: :charlie, tool: :nextjs, upvote: true, read_at: 3.days.ago },
    { user: :charlie, tool: :typescript, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :charlie, tool: :vue, upvote: true, read_at: 2.days.ago },
    { user: :charlie, tool: :nuxt, upvote: true, read_at: 1.day.ago },
    { user: :charlie, tool: :svelte, upvote: true, read_at: 3.days.ago },
    { user: :charlie, tool: :sveltekit, upvote: true, read_at: 2.days.ago },
    { user: :charlie, tool: :esbuild, upvote: true, read_at: 1.day.ago },
    { user: :charlie, tool: :swc, upvote: true, read_at: 2.days.ago },
    { user: :charlie, tool: :jest, upvote: true, read_at: 3.days.ago },
    { user: :charlie, tool: :vitest, upvote: true, read_at: 1.day.ago },
    { user: :charlie, tool: :playwright, upvote: true, read_at: 2.days.ago },
    { user: :charlie, tool: :cypress, upvote: true, read_at: 3.days.ago },
    { user: :charlie, tool: :eslint, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :charlie, tool: :prettier, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :charlie, tool: :vercel, upvote: true, read_at: 1.day.ago },
    { user: :charlie, tool: :netlify, upvote: true, read_at: 2.days.ago },
    { user: :diana, tool: :pgvector, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :diana, tool: :openai, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :diana, tool: :langchain, upvote: true, read_at: 2.days.ago },
    { user: :diana, tool: :jupyter, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :diana, tool: :pytest, upvote: true, read_at: 5.days.ago },
    { user: :diana, tool: :fastapi, upvote: true, read_at: 1.day.ago },
    { user: :diana, tool: :django, upvote: true, read_at: 2.days.ago },
    { user: :diana, tool: :flask, upvote: true, read_at: 3.days.ago },
    { user: :diana, tool: :mongodb, upvote: true, read_at: 4.days.ago },
    { user: :diana, tool: :black, upvote: true, read_at: 5.days.ago },
    { user: :diana, tool: :mypy, upvote: true, read_at: 6.days.ago },
    { user: :eve, tool: :prometheus, upvote: true, favorite: true, read_at: 1.day.ago },
    { user: :eve, tool: :grafana, upvote: true, read_at: 1.day.ago },
    { user: :eve, tool: :sentry, upvote: true, read_at: 2.days.ago },
    { user: :eve, tool: :datadog, upvote: true, read_at: 3.days.ago },
    { user: :eve, tool: :auth0, upvote: true, read_at: 1.day.ago },
    { user: :eve, tool: :okta, upvote: true, read_at: 2.days.ago },
    { user: :frank, tool: :rails, upvote: true, read_at: 2.days.ago },
    { user: :frank, tool: :github, upvote: true, read_at: 1.day.ago },
    { user: :frank, tool: :gitlab, upvote: true, read_at: 2.days.ago },
    { user: :frank, tool: :linear, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :frank, tool: :notion, upvote: true, read_at: 6.days.ago },
    { user: :frank, tool: :airtable, upvote: true, read_at: 7.days.ago },
    { user: :frank, tool: :zapier, upvote: true, read_at: 8.days.ago },
    { user: :frank, tool: :n8n, upvote: true, read_at: 9.days.ago },
    { user: :grace, tool: :react, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :grace, tool: :vite, upvote: true, read_at: 2.days.ago },
    { user: :grace, tool: :nextjs, upvote: true, read_at: 1.day.ago },
    { user: :grace, tool: :typescript, upvote: true, read_at: 3.days.ago },
    { user: :grace, tool: :tailwind, upvote: true, read_at: 4.days.ago },
    { user: :grace, tool: :storybook, upvote: true, read_at: 5.days.ago },
    { user: :henry, tool: :redis, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :henry, tool: :elasticsearch, upvote: true, read_at: 5.days.ago },
    { user: :henry, tool: :postgres, upvote: true, read_at: 6.days.ago },
    { user: :henry, tool: :mysql, upvote: true, read_at: 7.days.ago },
    { user: :henry, tool: :express, upvote: true, read_at: 8.days.ago },
    { user: :henry, tool: :nestjs, upvote: true, read_at: 9.days.ago },
    { user: :henry, tool: :golang, upvote: true, favorite: true, read_at: 10.days.ago },
    { user: :henry, tool: :rust, upvote: true, read_at: 11.days.ago },
    { user: :henry, tool: :graphql, upvote: true, read_at: 12.days.ago },
    { user: :henry, tool: :apollo, upvote: true, read_at: 13.days.ago },
    { user: :henry, tool: :prisma, upvote: true, read_at: 14.days.ago },
    { user: :henry, tool: :sequelize, upvote: true, read_at: 15.days.ago },
    { user: :henry, tool: :typeorm, upvote: true, read_at: 16.days.ago },
    { user: :henry, tool: :stripe, upvote: true, read_at: 17.days.ago },
    { user: :henry, tool: :twilio, upvote: true, read_at: 18.days.ago },
    { user: :henry, tool: :sendgrid, upvote: true, read_at: 19.days.ago },
    { user: :ivy, tool: :tailwind, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :ivy, tool: :react, upvote: true, read_at: 4.days.ago },
    { user: :ivy, tool: :vue, upvote: true, read_at: 5.days.ago },
    { user: :ivy, tool: :svelte, upvote: true, read_at: 6.days.ago },
    { user: :ivy, tool: :storybook, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :ivy, tool: :vite, upvote: true, read_at: 4.days.ago },
    { user: :ivy, tool: :nextjs, upvote: true, read_at: 3.days.ago },
    { user: :ivy, tool: :nuxt, upvote: true, read_at: 2.days.ago },
    { user: :ivy, tool: :sveltekit, upvote: true, read_at: 1.day.ago },
    { user: :jack, tool: :jenkins, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :jack, tool: :gha, upvote: true, read_at: 6.days.ago },
    { user: :jack, tool: :circleci, upvote: true, read_at: 1.day.ago },
    { user: :jack, tool: :gitlab_ci, upvote: true, read_at: 2.days.ago },
    { user: :jack, tool: :jest, upvote: true, read_at: 3.days.ago },
    { user: :jack, tool: :vitest, upvote: true, read_at: 4.days.ago },
    { user: :jack, tool: :playwright, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :jack, tool: :cypress, upvote: true, read_at: 6.days.ago },
    { user: :jack, tool: :pytest, upvote: true, read_at: 7.days.ago },
    { user: :kate, tool: :jupyter, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :kate, tool: :langchain, upvote: true, read_at: 3.days.ago },
    { user: :kate, tool: :openai, upvote: true, read_at: 2.days.ago },
    { user: :kate, tool: :pgvector, upvote: true, read_at: 5.days.ago },
    { user: :kate, tool: :pytest, upvote: true, read_at: 6.days.ago },
    { user: :kate, tool: :fastapi, upvote: true, read_at: 7.days.ago },
    { user: :kate, tool: :django, upvote: true, read_at: 8.days.ago },
    { user: :kate, tool: :mongodb, upvote: true, read_at: 9.days.ago },
    { user: :kate, tool: :black, upvote: true, read_at: 10.days.ago },
    { user: :kate, tool: :mypy, upvote: true, read_at: 11.days.ago },
    { user: :liam, tool: :sentry, upvote: true, favorite: true, read_at: 1.day.ago },
    { user: :liam, tool: :datadog, upvote: true, read_at: 2.days.ago },
    { user: :liam, tool: :prometheus, upvote: true, read_at: 3.days.ago },
    { user: :liam, tool: :grafana, upvote: true, read_at: 4.days.ago },
    { user: :liam, tool: :elasticsearch, upvote: true, read_at: 5.days.ago },
    { user: :liam, tool: :k8s, upvote: true, read_at: 6.days.ago },
    { user: :liam, tool: :docker, upvote: true, read_at: 7.days.ago },
    { user: :liam, tool: :terraform, upvote: true, read_at: 8.days.ago },
    { user: :liam, tool: :aws, upvote: true, read_at: 9.days.ago },
    { user: :liam, tool: :gcp, upvote: true, read_at: 10.days.ago },
    { user: :mia, tool: :terraform, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :mia, tool: :k8s, upvote: true, read_at: 6.days.ago },
    { user: :mia, tool: :docker, upvote: true, read_at: 7.days.ago },
    { user: :mia, tool: :aws, upvote: true, read_at: 8.days.ago },
    { user: :mia, tool: :gcp, upvote: true, read_at: 9.days.ago },
    { user: :mia, tool: :azure, upvote: true, read_at: 10.days.ago },
    { user: :mia, tool: :graphql, upvote: true, read_at: 11.days.ago },
    { user: :mia, tool: :apollo, upvote: true, read_at: 12.days.ago },
    { user: :mia, tool: :golang, upvote: true, read_at: 13.days.ago },
    { user: :mia, tool: :rust, upvote: true, read_at: 14.days.ago }
  ]
  
  # Add more explicit interactions for variety
  # Each user has additional interactions with tools relevant to their expertise
  additional_tool_interactions = [
    { user: :alice, tool: :github, upvote: true, read_at: 1.day.ago },
    { user: :alice, tool: :rubocop, upvote: true, read_at: 2.days.ago },
    { user: :bob, tool: :ansible, upvote: true, read_at: 7.days.ago },
    { user: :bob, tool: :aws, upvote: true, read_at: 6.days.ago },
    { user: :bob, tool: :gcp, upvote: true, read_at: 5.days.ago },
    { user: :bob, tool: :azure, upvote: true, read_at: 4.days.ago },
    { user: :charlie, tool: :nextjs, upvote: true, read_at: 3.days.ago },
    { user: :charlie, tool: :typescript, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :charlie, tool: :vue, upvote: true, read_at: 2.days.ago },
    { user: :charlie, tool: :nuxt, upvote: true, read_at: 1.day.ago },
    { user: :charlie, tool: :svelte, upvote: true, read_at: 3.days.ago },
    { user: :charlie, tool: :sveltekit, upvote: true, read_at: 2.days.ago },
    { user: :charlie, tool: :esbuild, upvote: true, read_at: 1.day.ago },
    { user: :charlie, tool: :swc, upvote: true, read_at: 2.days.ago },
    { user: :charlie, tool: :jest, upvote: true, read_at: 3.days.ago },
    { user: :charlie, tool: :vitest, upvote: true, read_at: 1.day.ago },
    { user: :charlie, tool: :playwright, upvote: true, read_at: 2.days.ago },
    { user: :charlie, tool: :cypress, upvote: true, read_at: 3.days.ago },
    { user: :charlie, tool: :eslint, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :charlie, tool: :prettier, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :charlie, tool: :vercel, upvote: true, read_at: 1.day.ago },
    { user: :charlie, tool: :netlify, upvote: true, read_at: 2.days.ago },
    { user: :diana, tool: :jupyter, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :diana, tool: :pytest, upvote: true, read_at: 5.days.ago },
    { user: :diana, tool: :fastapi, upvote: true, read_at: 1.day.ago },
    { user: :diana, tool: :django, upvote: true, read_at: 2.days.ago },
    { user: :diana, tool: :flask, upvote: true, read_at: 3.days.ago },
    { user: :diana, tool: :mongodb, upvote: true, read_at: 4.days.ago },
    { user: :diana, tool: :black, upvote: true, read_at: 5.days.ago },
    { user: :diana, tool: :mypy, upvote: true, read_at: 6.days.ago },
    { user: :eve, tool: :sentry, upvote: true, read_at: 2.days.ago },
    { user: :eve, tool: :datadog, upvote: true, read_at: 3.days.ago },
    { user: :eve, tool: :auth0, upvote: true, read_at: 1.day.ago },
    { user: :eve, tool: :okta, upvote: true, read_at: 2.days.ago },
    { user: :frank, tool: :github, upvote: true, read_at: 1.day.ago },
    { user: :frank, tool: :gitlab, upvote: true, read_at: 2.days.ago },
    { user: :frank, tool: :linear, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :frank, tool: :notion, upvote: true, read_at: 6.days.ago },
    { user: :frank, tool: :airtable, upvote: true, read_at: 7.days.ago },
    { user: :frank, tool: :zapier, upvote: true, read_at: 8.days.ago },
    { user: :frank, tool: :n8n, upvote: true, read_at: 9.days.ago },
    { user: :grace, tool: :nextjs, upvote: true, read_at: 1.day.ago },
    { user: :grace, tool: :typescript, upvote: true, read_at: 3.days.ago },
    { user: :grace, tool: :tailwind, upvote: true, read_at: 4.days.ago },
    { user: :grace, tool: :storybook, upvote: true, read_at: 5.days.ago },
    { user: :henry, tool: :mysql, upvote: true, read_at: 7.days.ago },
    { user: :henry, tool: :express, upvote: true, read_at: 8.days.ago },
    { user: :henry, tool: :nestjs, upvote: true, read_at: 9.days.ago },
    { user: :henry, tool: :golang, upvote: true, favorite: true, read_at: 10.days.ago },
    { user: :henry, tool: :rust, upvote: true, read_at: 11.days.ago },
    { user: :henry, tool: :graphql, upvote: true, read_at: 12.days.ago },
    { user: :henry, tool: :apollo, upvote: true, read_at: 13.days.ago },
    { user: :henry, tool: :prisma, upvote: true, read_at: 14.days.ago },
    { user: :henry, tool: :sequelize, upvote: true, read_at: 15.days.ago },
    { user: :henry, tool: :typeorm, upvote: true, read_at: 16.days.ago },
    { user: :henry, tool: :stripe, upvote: true, read_at: 17.days.ago },
    { user: :henry, tool: :twilio, upvote: true, read_at: 18.days.ago },
    { user: :henry, tool: :sendgrid, upvote: true, read_at: 19.days.ago },
    { user: :ivy, tool: :vue, upvote: true, read_at: 5.days.ago },
    { user: :ivy, tool: :svelte, upvote: true, read_at: 6.days.ago },
    { user: :ivy, tool: :storybook, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :ivy, tool: :vite, upvote: true, read_at: 4.days.ago },
    { user: :ivy, tool: :nextjs, upvote: true, read_at: 3.days.ago },
    { user: :ivy, tool: :nuxt, upvote: true, read_at: 2.days.ago },
    { user: :ivy, tool: :sveltekit, upvote: true, read_at: 1.day.ago },
    { user: :jack, tool: :circleci, upvote: true, read_at: 1.day.ago },
    { user: :jack, tool: :gitlab_ci, upvote: true, read_at: 2.days.ago },
    { user: :jack, tool: :jest, upvote: true, read_at: 3.days.ago },
    { user: :jack, tool: :vitest, upvote: true, read_at: 4.days.ago },
    { user: :jack, tool: :playwright, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :jack, tool: :cypress, upvote: true, read_at: 6.days.ago },
    { user: :jack, tool: :pytest, upvote: true, read_at: 7.days.ago },
    { user: :kate, tool: :pgvector, upvote: true, read_at: 5.days.ago },
    { user: :kate, tool: :pytest, upvote: true, read_at: 6.days.ago },
    { user: :kate, tool: :fastapi, upvote: true, read_at: 7.days.ago },
    { user: :kate, tool: :django, upvote: true, read_at: 8.days.ago },
    { user: :kate, tool: :mongodb, upvote: true, read_at: 9.days.ago },
    { user: :kate, tool: :black, upvote: true, read_at: 10.days.ago },
    { user: :kate, tool: :mypy, upvote: true, read_at: 11.days.ago },
    { user: :liam, tool: :grafana, upvote: true, read_at: 4.days.ago },
    { user: :liam, tool: :elasticsearch, upvote: true, read_at: 5.days.ago },
    { user: :liam, tool: :k8s, upvote: true, read_at: 6.days.ago },
    { user: :liam, tool: :docker, upvote: true, read_at: 7.days.ago },
    { user: :liam, tool: :terraform, upvote: true, read_at: 8.days.ago },
    { user: :liam, tool: :aws, upvote: true, read_at: 9.days.ago },
    { user: :liam, tool: :gcp, upvote: true, read_at: 10.days.ago },
    { user: :mia, tool: :aws, upvote: true, read_at: 8.days.ago },
    { user: :mia, tool: :gcp, upvote: true, read_at: 9.days.ago },
    { user: :mia, tool: :azure, upvote: true, read_at: 10.days.ago },
    { user: :mia, tool: :graphql, upvote: true, read_at: 11.days.ago },
    { user: :mia, tool: :apollo, upvote: true, read_at: 12.days.ago },
    { user: :mia, tool: :golang, upvote: true, read_at: 13.days.ago },
    { user: :mia, tool: :rust, upvote: true, read_at: 14.days.ago }
  ]
  user_tool_defs.concat(additional_tool_interactions)

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
    # Core interactions
    { user: :alice, submission: :hotwire_dashboard, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :alice, submission: :pgvector_search, upvote: true, read_at: 2.days.ago },
    { user: :alice, submission: :gha_ci, upvote: true, read_at: 4.days.ago },
    { user: :alice, submission: :rubocop_config, upvote: true, read_at: 1.day.ago },
    { user: :alice, submission: :supabase_realtime, upvote: true, read_at: 1.day.ago },
    { user: :alice, submission: :firebase_functions, upvote: true, read_at: 2.days.ago },
    { user: :bob, submission: :gha_ci, upvote: true, read_at: 4.days.ago },
    { user: :bob, submission: :k8s_deploy, upvote: true, favorite: true, read_at: 4.days.ago },
    { user: :bob, submission: :terraform_aws, upvote: true, read_at: 6.days.ago },
    { user: :bob, submission: :ansible_playbooks, upvote: true, favorite: true, read_at: 7.days.ago },
    { user: :bob, submission: :aws_lambda_cold_starts, upvote: true, read_at: 1.day.ago },
    { user: :bob, submission: :gcp_cloud_run, upvote: true, read_at: 2.days.ago },
    { user: :bob, submission: :azure_functions, upvote: true, read_at: 3.days.ago },
    { user: :bob, submission: :heroku_dynos, upvote: true, read_at: 4.days.ago },
    { user: :charlie, submission: :react_vs_turbo, upvote: true, favorite: true, read_at: 1.day.ago },
    { user: :charlie, submission: :vite_setup, upvote: true, favorite: true, read_at: 2.days.ago },
    { user: :charlie, submission: :nextjs_ssr, upvote: true, read_at: 1.day.ago },
    { user: :charlie, submission: :typescript_advanced, upvote: true, read_at: 12.days.ago },
    { user: :charlie, submission: :vue_composition_api, upvote: true, read_at: 1.day.ago },
    { user: :charlie, submission: :nuxt_ssr_performance, upvote: true, read_at: 2.days.ago },
    { user: :charlie, submission: :svelte_reactive_patterns, upvote: true, read_at: 3.days.ago },
    { user: :charlie, submission: :sveltekit_routing, upvote: true, read_at: 4.days.ago },
    { user: :charlie, submission: :vercel_edge_functions, upvote: true, read_at: 1.day.ago },
    { user: :charlie, submission: :netlify_functions, upvote: true, read_at: 2.days.ago },
    { user: :charlie, submission: :webpack_code_splitting, upvote: true, read_at: 3.days.ago },
    { user: :charlie, submission: :esbuild_config, upvote: true, read_at: 4.days.ago },
    { user: :charlie, submission: :swc_rust_compiler, upvote: true, read_at: 5.days.ago },
    { user: :charlie, submission: :eslint_rules, upvote: true, read_at: 2.days.ago },
    { user: :charlie, submission: :prettier_integration, upvote: true, read_at: 3.days.ago },
    { user: :diana, submission: :langchain_agents, upvote: true, favorite: true, read_at: 2.days.ago },
    { user: :diana, submission: :pgvector_search, upvote: true, read_at: 2.days.ago },
    { user: :diana, submission: :pytest_patterns, upvote: true, read_at: 4.days.ago },
    { user: :diana, submission: :fastapi_async, upvote: true, read_at: 1.day.ago },
    { user: :diana, submission: :django_orm_optimization, upvote: true, read_at: 2.days.ago },
    { user: :diana, submission: :flask_blueprints, upvote: true, read_at: 3.days.ago },
    { user: :diana, submission: :mongodb_aggregation, upvote: true, read_at: 9.days.ago },
    { user: :diana, submission: :black_formatting, upvote: true, read_at: 5.days.ago },
    { user: :diana, submission: :mypy_gradual_typing, upvote: true, read_at: 6.days.ago },
    { user: :eve, submission: :observability_stack, upvote: true, favorite: true, read_at: 12.hours.ago },
    { user: :eve, submission: :auth0_integration, upvote: true, read_at: 1.day.ago },
    { user: :eve, submission: :okta_sso, upvote: true, read_at: 2.days.ago },
    { user: :frank, submission: :n8n_workflows, upvote: true, read_at: 3.days.ago },
    { user: :frank, submission: :zapier_zaps, upvote: true, read_at: 4.days.ago },
    { user: :frank, submission: :airtable_api, upvote: true, read_at: 5.days.ago },
    { user: :frank, submission: :notion_api, upvote: true, read_at: 6.days.ago },
    { user: :frank, submission: :linear_api, upvote: true, read_at: 7.days.ago },
    { user: :grace, submission: :react_native_setup, upvote: true, favorite: true, read_at: 13.days.ago },
    { user: :henry, submission: :redis_caching, upvote: true, read_at: 4.days.ago },
    { user: :henry, submission: :elasticsearch_search, upvote: true, favorite: true, read_at: 5.days.ago },
    { user: :henry, submission: :microservices_architecture, upvote: true, read_at: 14.days.ago },
    { user: :henry, submission: :express_middleware, upvote: true, read_at: 4.days.ago },
    { user: :henry, submission: :nestjs_dependency_injection, upvote: true, read_at: 5.days.ago },
    { user: :henry, submission: :golang_concurrency, upvote: true, read_at: 6.days.ago },
    { user: :henry, submission: :rust_ownership, upvote: true, read_at: 7.days.ago },
    { user: :henry, submission: :mysql_indexing, upvote: true, read_at: 8.days.ago },
    { user: :henry, submission: :graphql_schema_design, upvote: true, read_at: 1.day.ago },
    { user: :henry, submission: :apollo_server_setup, upvote: true, read_at: 2.days.ago },
    { user: :henry, submission: :prisma_migrations, upvote: true, read_at: 3.days.ago },
    { user: :henry, submission: :sequelize_associations, upvote: true, read_at: 4.days.ago },
    { user: :henry, submission: :typeorm_entities, upvote: true, read_at: 5.days.ago },
    { user: :henry, submission: :stripe_webhooks, upvote: true, read_at: 3.days.ago },
    { user: :henry, submission: :twilio_voice_api, upvote: true, read_at: 4.days.ago },
    { user: :henry, submission: :sendgrid_templates, upvote: true, read_at: 5.days.ago },
    { user: :ivy, submission: :tailwind_components, upvote: true, favorite: true, read_at: 3.days.ago },
    { user: :ivy, submission: :storybook_addons, upvote: true, read_at: 1.day.ago },
    { user: :jack, submission: :jenkins_pipelines, upvote: true, read_at: 8.days.ago },
    { user: :jack, submission: :circleci_workflows, upvote: true, read_at: 1.day.ago },
    { user: :jack, submission: :gitlab_ci_variables, upvote: true, read_at: 2.days.ago },
    { user: :jack, submission: :jest_mocking, upvote: true, read_at: 1.day.ago },
    { user: :jack, submission: :vitest_vs_jest, upvote: true, read_at: 2.days.ago },
    { user: :jack, submission: :playwright_automation, upvote: true, read_at: 3.days.ago },
    { user: :jack, submission: :cypress_component_testing, upvote: true, read_at: 4.days.ago },
    { user: :kate, submission: :jupyter_notebooks, upvote: true, favorite: true, read_at: 11.days.ago },
    { user: :kate, submission: :ml_pipelines, upvote: true, favorite: true, read_at: 15.days.ago },
    { user: :liam, submission: :sentry_integration, upvote: true, favorite: true, read_at: 9.days.ago },
    { user: :liam, submission: :datadog_dashboards, upvote: true, read_at: 10.days.ago },
    { user: :mia, submission: :api_design, upvote: true, read_at: 16.days.ago },
    { user: :mia, submission: :distributed_systems, upvote: true, favorite: true, read_at: 17.days.ago }
  ]
  
  # Add more explicit interactions - users read and upvote submissions relevant to their interests
  additional_submission_interactions = [
    { user: :alice, submission: :gha_ci, upvote: true, read_at: 4.days.ago },
    { user: :alice, submission: :rubocop_config, upvote: true, read_at: 1.day.ago },
    { user: :alice, submission: :supabase_realtime, upvote: true, read_at: 1.day.ago },
    { user: :alice, submission: :firebase_functions, upvote: true, read_at: 2.days.ago },
    { user: :bob, submission: :aws_lambda_cold_starts, upvote: true, read_at: 1.day.ago },
    { user: :bob, submission: :gcp_cloud_run, upvote: true, read_at: 2.days.ago },
    { user: :bob, submission: :azure_functions, upvote: true, read_at: 3.days.ago },
    { user: :bob, submission: :heroku_dynos, upvote: true, read_at: 4.days.ago },
    { user: :charlie, submission: :vue_composition_api, upvote: true, read_at: 1.day.ago },
    { user: :charlie, submission: :nuxt_ssr_performance, upvote: true, read_at: 2.days.ago },
    { user: :charlie, submission: :svelte_reactive_patterns, upvote: true, read_at: 3.days.ago },
    { user: :charlie, submission: :sveltekit_routing, upvote: true, read_at: 4.days.ago },
    { user: :charlie, submission: :vercel_edge_functions, upvote: true, read_at: 1.day.ago },
    { user: :charlie, submission: :netlify_functions, upvote: true, read_at: 2.days.ago },
    { user: :charlie, submission: :webpack_code_splitting, upvote: true, read_at: 3.days.ago },
    { user: :charlie, submission: :esbuild_config, upvote: true, read_at: 4.days.ago },
    { user: :charlie, submission: :swc_rust_compiler, upvote: true, read_at: 5.days.ago },
    { user: :charlie, submission: :eslint_rules, upvote: true, read_at: 2.days.ago },
    { user: :charlie, submission: :prettier_integration, upvote: true, read_at: 3.days.ago },
    { user: :diana, submission: :pytest_patterns, upvote: true, read_at: 4.days.ago },
    { user: :diana, submission: :fastapi_async, upvote: true, read_at: 1.day.ago },
    { user: :diana, submission: :django_orm_optimization, upvote: true, read_at: 2.days.ago },
    { user: :diana, submission: :flask_blueprints, upvote: true, read_at: 3.days.ago },
    { user: :diana, submission: :mongodb_aggregation, upvote: true, read_at: 9.days.ago },
    { user: :diana, submission: :black_formatting, upvote: true, read_at: 5.days.ago },
    { user: :diana, submission: :mypy_gradual_typing, upvote: true, read_at: 6.days.ago },
    { user: :eve, submission: :auth0_integration, upvote: true, read_at: 1.day.ago },
    { user: :eve, submission: :okta_sso, upvote: true, read_at: 2.days.ago },
    { user: :frank, submission: :n8n_workflows, upvote: true, read_at: 3.days.ago },
    { user: :frank, submission: :zapier_zaps, upvote: true, read_at: 4.days.ago },
    { user: :frank, submission: :airtable_api, upvote: true, read_at: 5.days.ago },
    { user: :frank, submission: :notion_api, upvote: true, read_at: 6.days.ago },
    { user: :frank, submission: :linear_api, upvote: true, read_at: 7.days.ago },
    { user: :henry, submission: :express_middleware, upvote: true, read_at: 4.days.ago },
    { user: :henry, submission: :nestjs_dependency_injection, upvote: true, read_at: 5.days.ago },
    { user: :henry, submission: :golang_concurrency, upvote: true, read_at: 6.days.ago },
    { user: :henry, submission: :rust_ownership, upvote: true, read_at: 7.days.ago },
    { user: :henry, submission: :mysql_indexing, upvote: true, read_at: 8.days.ago },
    { user: :henry, submission: :graphql_schema_design, upvote: true, read_at: 1.day.ago },
    { user: :henry, submission: :apollo_server_setup, upvote: true, read_at: 2.days.ago },
    { user: :henry, submission: :prisma_migrations, upvote: true, read_at: 3.days.ago },
    { user: :henry, submission: :sequelize_associations, upvote: true, read_at: 4.days.ago },
    { user: :henry, submission: :typeorm_entities, upvote: true, read_at: 5.days.ago },
    { user: :henry, submission: :stripe_webhooks, upvote: true, read_at: 3.days.ago },
    { user: :henry, submission: :twilio_voice_api, upvote: true, read_at: 4.days.ago },
    { user: :henry, submission: :sendgrid_templates, upvote: true, read_at: 5.days.ago },
    { user: :ivy, submission: :storybook_addons, upvote: true, read_at: 1.day.ago },
    { user: :jack, submission: :circleci_workflows, upvote: true, read_at: 1.day.ago },
    { user: :jack, submission: :gitlab_ci_variables, upvote: true, read_at: 2.days.ago },
    { user: :jack, submission: :jest_mocking, upvote: true, read_at: 1.day.ago },
    { user: :jack, submission: :vitest_vs_jest, upvote: true, read_at: 2.days.ago },
    { user: :jack, submission: :playwright_automation, upvote: true, read_at: 3.days.ago },
    { user: :jack, submission: :cypress_component_testing, upvote: true, read_at: 4.days.ago }
  ]
  user_submission_defs.concat(additional_submission_interactions)

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
    # User follows tools
    { user: :alice, followable: tools[:pgvector] },
    { user: :alice, followable: tools[:rails] },
    { user: :alice, followable: tools[:turbo] },
    { user: :alice, followable: tools[:postgres] },
    { user: :bob, followable: tools[:rails] },
    { user: :bob, followable: tools[:docker] },
    { user: :bob, followable: tools[:k8s] },
    { user: :bob, followable: tools[:terraform] },
    { user: :bob, followable: tools[:aws] },
    { user: :charlie, followable: tools[:react] },
    { user: :charlie, followable: tools[:vite] },
    { user: :charlie, followable: tools[:nextjs] },
    { user: :charlie, followable: tools[:typescript] },
    { user: :charlie, followable: tools[:vue] },
    { user: :charlie, followable: tools[:svelte] },
    { user: :diana, followable: tools[:openai] },
    { user: :diana, followable: tools[:pgvector] },
    { user: :diana, followable: tools[:langchain] },
    { user: :diana, followable: tools[:jupyter] },
    { user: :diana, followable: tools[:fastapi] },
    { user: :eve, followable: tools[:gha] },
    { user: :eve, followable: tools[:prometheus] },
    { user: :eve, followable: tools[:grafana] },
    { user: :eve, followable: tools[:sentry] },
    { user: :frank, followable: tools[:github] },
    { user: :frank, followable: tools[:linear] },
    { user: :grace, followable: tools[:react] },
    { user: :grace, followable: tools[:vite] },
    { user: :grace, followable: tools[:nextjs] },
    { user: :henry, followable: tools[:redis] },
    { user: :henry, followable: tools[:elasticsearch] },
    { user: :henry, followable: tools[:postgres] },
    { user: :henry, followable: tools[:golang] },
    { user: :henry, followable: tools[:graphql] },
    { user: :ivy, followable: tools[:tailwind] },
    { user: :ivy, followable: tools[:react] },
    { user: :ivy, followable: tools[:storybook] },
    { user: :jack, followable: tools[:jenkins] },
    { user: :jack, followable: tools[:playwright] },
    { user: :jack, followable: tools[:cypress] },
    { user: :kate, followable: tools[:jupyter] },
    { user: :kate, followable: tools[:openai] },
    { user: :kate, followable: tools[:langchain] },
    { user: :liam, followable: tools[:sentry] },
    { user: :liam, followable: tools[:datadog] },
    { user: :liam, followable: tools[:prometheus] },
    { user: :mia, followable: tools[:terraform] },
    { user: :mia, followable: tools[:k8s] },
    { user: :mia, followable: tools[:golang] },
    # User follows lists
    { user: :alice, followable: lists[:ai_retrieval] },
    { user: :bob, followable: lists[:rails_stack] },
    { user: :bob, followable: lists[:platform_ops] },
    { user: :charlie, followable: lists[:frontend_choices] },
    { user: :diana, followable: lists[:ai_retrieval] },
    { user: :eve, followable: lists[:platform_ops] },
    { user: :eve, followable: lists[:security_watch] },
    { user: :frank, followable: lists[:rails_stack] },
    { user: :grace, followable: lists[:frontend_choices] },
    { user: :henry, followable: lists[:platform_ops] },
    { user: :ivy, followable: lists[:frontend_choices] },
    { user: :jack, followable: lists[:platform_ops] },
    { user: :kate, followable: lists[:ai_retrieval] },
    { user: :liam, followable: lists[:platform_ops] },
    { user: :mia, followable: lists[:platform_ops] },
    # User follows tags
    { user: :alice, followable: tags[:rails] },
    { user: :alice, followable: tags[:backend] },
    { user: :bob, followable: tags[:devops] },
    { user: :bob, followable: tags[:kubernetes] },
    { user: :charlie, followable: tags[:frontend] },
    { user: :charlie, followable: tags[:react] },
    { user: :charlie, followable: tags[:javascript] },
    { user: :diana, followable: tags[:ai] },
    { user: :diana, followable: tags[:llm] },
    { user: :diana, followable: tags[:data] },
    { user: :diana, followable: tags[:python] },
    { user: :eve, followable: tags[:security] },
    { user: :eve, followable: tags[:observability] },
    { user: :frank, followable: tags[:productivity] },
    { user: :grace, followable: tags[:frontend] },
    { user: :grace, followable: tags[:react] },
    { user: :henry, followable: tags[:backend] },
    { user: :henry, followable: tags[:data] },
    { user: :ivy, followable: tags[:frontend] },
    { user: :jack, followable: tags[:testing] },
    { user: :kate, followable: tags[:ai] },
    { user: :kate, followable: tags[:data] },
    { user: :liam, followable: tags[:observability] },
    { user: :liam, followable: tags[:devops] },
    { user: :mia, followable: tags[:backend] },
    { user: :mia, followable: tags[:devops] },
    # User follows users
    { user: :frank, followable: users[:alice] },
    { user: :frank, followable: users[:bob] },
    { user: :frank, followable: users[:charlie] },
    { user: :alice, followable: users[:diana] },
    { user: :bob, followable: users[:alice] },
    { user: :charlie, followable: users[:ivy] },
    { user: :diana, followable: users[:kate] },
    { user: :eve, followable: users[:liam] },
    { user: :grace, followable: users[:charlie] },
    { user: :henry, followable: users[:mia] },
    { user: :ivy, followable: users[:charlie] },
    { user: :jack, followable: users[:bob] },
    { user: :kate, followable: users[:diana] },
    { user: :liam, followable: users[:eve] },
    { user: :mia, followable: users[:henry] },
    { user: :alice, followable: users[:bob] },
    { user: :bob, followable: users[:charlie] },
    { user: :charlie, followable: users[:alice] }
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
    # Comments on tools
    { user: :alice, commentable: tools[:rails], body: "Hotwire keeps us fast without a SPA. The server-first approach really shines for our use case.", created_at: 4.days.ago },
    { user: :charlie, commentable: tools[:react], body: "Still great for complex client state. React's ecosystem is unmatched for component libraries.", created_at: 5.days.ago },
    { user: :charlie, commentable: tools[:vite], body: "Vite's HMR is incredibly fast. Game changer for development. Build times are also much better than Webpack.", created_at: 2.days.ago },
    { user: :grace, commentable: tools[:vite], body: "Agreed! The build times are also much better than Webpack. Our CI pipeline is 3x faster now.", created_at: 1.day.ago, parent: 2 },
    { user: :henry, commentable: tools[:redis], body: "Redis is essential for our caching layer. Great performance and the pub/sub features are powerful.", created_at: 3.days.ago },
    { user: :ivy, commentable: tools[:tailwind], body: "Tailwind makes prototyping so much faster. Love the utility classes and the JIT compiler is amazing.", created_at: 2.days.ago },
    { user: :jack, commentable: tools[:jenkins], body: "Jenkins pipelines are powerful but can get complex. Good examples here helped me understand declarative syntax.", created_at: 4.days.ago },
    { user: :kate, commentable: tools[:jupyter], body: "Jupyter notebooks are perfect for ML experimentation and visualization. The interactive nature is invaluable.", created_at: 3.days.ago },
    { user: :liam, commentable: tools[:sentry], body: "Sentry's error grouping and release tracking saved us hours of debugging. The source map integration is seamless.", created_at: 2.days.ago },
    { user: :mia, commentable: tools[:terraform], body: "Terraform's state management is crucial for infrastructure as code. The plan/apply workflow prevents many mistakes.", created_at: 5.days.ago },
    { user: :diana, commentable: tools[:pgvector], body: "pgvector makes semantic search so much easier than external services. Having it in Postgres is a game changer.", created_at: 3.days.ago },
    { user: :bob, commentable: tools[:k8s], body: "Kubernetes has a learning curve but it's worth it for orchestration. The declarative approach is powerful.", created_at: 7.days.ago },
    { user: :eve, commentable: tools[:prometheus], body: "Prometheus metrics are essential for observability. Great tool with excellent integration ecosystem.", created_at: 1.day.ago },
    { user: :frank, commentable: tools[:rails], body: "Rails convention over configuration speeds up development significantly. The ecosystem is mature and reliable.", created_at: 2.days.ago },
    { user: :charlie, commentable: tools[:nextjs], body: "Next.js SSR patterns are excellent. ISR and edge functions make it perfect for global apps.", created_at: 1.day.ago },
    { user: :charlie, commentable: tools[:typescript], body: "TypeScript catches so many bugs at compile time. The type system is powerful once you learn it.", created_at: 2.days.ago },
    { user: :charlie, commentable: tools[:vue], body: "Vue 3's Composition API is great. Much better than Options API for complex components.", created_at: 1.day.ago },
    { user: :charlie, commentable: tools[:svelte], body: "Svelte's compiler approach is brilliant. No runtime overhead and the code is so clean.", created_at: 2.days.ago },
    { user: :diana, commentable: tools[:fastapi], body: "FastAPI's automatic OpenAPI docs are amazing. The async support is excellent for I/O-bound APIs.", created_at: 1.day.ago },
    { user: :diana, commentable: tools[:django], body: "Django's ORM is powerful but can be slow. The admin interface is still unmatched though.", created_at: 2.days.ago },
    { user: :henry, commentable: tools[:golang], body: "Go's concurrency model with goroutines is elegant. Perfect for building high-performance services.", created_at: 3.days.ago },
    { user: :henry, commentable: tools[:graphql], body: "GraphQL's type system and introspection are powerful. Apollo makes it production-ready.", created_at: 4.days.ago },
    { user: :henry, commentable: tools[:prisma], body: "Prisma's type-safe queries are a game changer. The migration system is also excellent.", created_at: 5.days.ago },
    { user: :jack, commentable: tools[:playwright], body: "Playwright is the future of E2E testing. The API is clean and the debugging tools are excellent.", created_at: 1.day.ago },
    { user: :jack, commentable: tools[:cypress], body: "Cypress's time-travel debugging is amazing. Great for understanding test failures.", created_at: 2.days.ago },
    { user: :ivy, commentable: tools[:storybook], body: "Storybook is essential for component libraries. The addon ecosystem is rich and powerful.", created_at: 1.day.ago },
    { user: :charlie, commentable: tools[:eslint], body: "ESLint keeps our code consistent. Custom rules help enforce team conventions.", created_at: 2.days.ago },
    { user: :charlie, commentable: tools[:prettier], body: "Prettier eliminates all formatting debates. Zero configuration needed.", created_at: 3.days.ago },
    { user: :alice, commentable: tools[:rubocop], body: "RuboCop keeps Ruby code consistent. Essential for team projects.", created_at: 4.days.ago },
    { user: :diana, commentable: tools[:black], body: "Black eliminates style debates. Zero configuration needed and it's fast.", created_at: 5.days.ago },
    { user: :diana, commentable: tools[:mypy], body: "mypy catches bugs early. Gradual typing makes it easy to adopt.", created_at: 6.days.ago },
    { user: :henry, commentable: tools[:stripe], body: "Stripe's API is well-designed. The webhook system is reliable and well-documented.", created_at: 3.days.ago },
    { user: :henry, commentable: tools[:twilio], body: "Twilio's API is powerful. Great for building communication features.", created_at: 4.days.ago },
    { user: :eve, commentable: tools[:auth0], body: "Auth0 handles auth complexity well. Great for enterprise apps with multiple identity providers.", created_at: 1.day.ago },
    { user: :frank, commentable: tools[:linear], body: "Linear is beautiful and fast. The keyboard shortcuts make it incredibly efficient.", created_at: 5.days.ago },
    { user: :frank, commentable: tools[:notion], body: "Notion is versatile. Great for documentation and wikis.", created_at: 6.days.ago },
    { user: :bob, commentable: tools[:aws], body: "AWS has everything but the learning curve is steep. Worth it for scale though.", created_at: 8.days.ago },
    { user: :bob, commentable: tools[:gcp], body: "GCP is great for data and ML workloads. The documentation is excellent.", created_at: 9.days.ago },
    { user: :charlie, commentable: tools[:vercel], body: "Vercel makes deployment trivial. Perfect for Next.js and JAMstack apps.", created_at: 1.day.ago },
    { user: :charlie, commentable: tools[:netlify], body: "Netlify is great for static sites. Built-in CI/CD and forms are convenient.", created_at: 2.days.ago },
    # Comments on submissions
    { user: :diana, commentable: submissions[:pgvector_search], body: "Loved the migration snippet with cosine index. The benchmarks were really helpful for planning.", created_at: 2.days.ago },
    { user: :bob, commentable: submissions[:k8s_deploy], body: "Blue/green example works well with Argo Rollouts. The manifest templates are production-ready.", created_at: 3.days.ago },
    { user: :eve, commentable: submissions[:observability_stack], body: "Please share the alert rules! The Prometheus + Grafana setup is exactly what we need.", created_at: 1.day.ago },
    { user: :alice, commentable: submissions[:react_vs_turbo], body: "Benchmarks were super helpful. The DX comparison section was particularly insightful.", created_at: 1.day.ago, parent: 0 },
    { user: :charlie, commentable: submissions[:vite_setup], body: "This guide helped me set up Vite in minutes. Clear and concise! The TypeScript config examples were perfect.", created_at: 2.days.ago },
    { user: :ivy, commentable: submissions[:tailwind_components], body: "The dark mode examples are exactly what I needed. Thanks! The component patterns are reusable.", created_at: 3.days.ago },
    { user: :henry, commentable: submissions[:redis_caching], body: "Cache invalidation strategies are well explained here. The patterns are production-tested.", created_at: 4.days.ago },
    { user: :bob, commentable: submissions[:terraform_aws], body: "Multi-region deployment patterns are solid. Used this in production and it works great.", created_at: 6.days.ago },
    { user: :liam, commentable: submissions[:sentry_integration], body: "Source maps integration was tricky until I found this guide. The release tracking setup is now seamless.", created_at: 9.days.ago },
    { user: :kate, commentable: submissions[:jupyter_notebooks], body: "Great tips on organizing notebooks for reproducible research. The version control patterns are helpful.", created_at: 11.days.ago },
    { user: :charlie, commentable: submissions[:typescript_advanced], body: "Conditional types are mind-bending but this article explains them well. The examples are clear.", created_at: 12.days.ago },
    { user: :grace, commentable: submissions[:react_native_setup], body: "iOS setup was straightforward with these instructions. The Android configuration was also helpful.", created_at: 13.days.ago },
    { user: :henry, commentable: submissions[:microservices_architecture], body: "Service communication patterns are well covered. Good reference for designing distributed systems.", created_at: 14.days.ago },
    { user: :mia, commentable: submissions[:api_design], body: "API versioning strategies are crucial. This covers all the important points with practical examples.", created_at: 16.days.ago },
    { user: :alice, commentable: submissions[:nextjs_ssr], body: "ISR is a game changer for performance. Great article! The edge functions section was also valuable.", created_at: 1.day.ago },
    { user: :charlie, commentable: submissions[:nextjs_ssr], body: "Edge functions are also worth exploring for global performance. The examples helped me understand the use cases.", created_at: 1.day.ago, parent: 44 },
    { user: :charlie, commentable: submissions[:vue_composition_api], body: "Great deep dive into Composition API. The composables examples are really helpful for reusable logic.", created_at: 1.day.ago },
    { user: :charlie, commentable: submissions[:nuxt_ssr_performance], body: "Performance optimization tips are solid. Improved our TTFB by 40% using these techniques.", created_at: 2.days.ago },
    { user: :diana, commentable: submissions[:fastapi_async], body: "Async patterns with FastAPI are well explained. The database connection pooling examples are helpful.", created_at: 1.day.ago },
    { user: :diana, commentable: submissions[:django_orm_optimization], body: "ORM optimization techniques are essential. Reduced our query count by 90% using select_related.", created_at: 2.days.ago },
    { user: :henry, commentable: submissions[:golang_concurrency], body: "Go concurrency patterns are well covered. The worker pool example is production-ready.", created_at: 6.days.ago },
    { user: :henry, commentable: submissions[:graphql_schema_design], body: "Schema design patterns are crucial. The evolution strategies section is particularly valuable.", created_at: 1.day.ago },
    { user: :henry, commentable: submissions[:prisma_migrations], body: "Prisma migrations workflow is well explained. The type-safe approach is a game changer.", created_at: 3.days.ago },
    { user: :jack, commentable: submissions[:playwright_automation], body: "Playwright tutorial is comprehensive. The page object patterns are helpful for maintainable tests.", created_at: 3.days.ago },
    { user: :jack, commentable: submissions[:jest_mocking], body: "Jest mocking patterns are essential. The manual mocks section helped me test complex dependencies.", created_at: 1.day.ago },
    { user: :ivy, commentable: submissions[:storybook_addons], body: "Storybook addons guide is helpful. The accessibility addon is a must-have for component libraries.", created_at: 1.day.ago },
    { user: :charlie, commentable: submissions[:eslint_rules], body: "Custom ESLint rules are powerful. The AST traversal examples helped me understand the internals.", created_at: 2.days.ago },
    { user: :charlie, commentable: submissions[:prettier_integration], body: "Prettier + ESLint setup is standard now. The eslint-config-prettier integration is seamless.", created_at: 3.days.ago },
    { user: :alice, commentable: submissions[:rubocop_config], body: "RuboCop configuration guide is helpful. The inheritance patterns keep configs DRY.", created_at: 4.days.ago },
    { user: :diana, commentable: submissions[:black_formatting], body: "Black setup is straightforward. The pre-commit hook integration is essential.", created_at: 5.days.ago },
    { user: :henry, commentable: submissions[:stripe_webhooks], body: "Stripe webhook handling is well explained. The idempotency patterns are crucial for payments.", created_at: 3.days.ago },
    { user: :eve, commentable: submissions[:auth0_integration], body: "Auth0 integration guide is comprehensive. The JWT token handling examples are helpful.", created_at: 1.day.ago },
    { user: :frank, commentable: submissions[:n8n_workflows], body: "n8n workflows are powerful. The error handling patterns helped me build reliable automations.", created_at: 3.days.ago },
    { user: :bob, commentable: submissions[:aws_lambda_cold_starts], body: "Cold start optimization techniques are valuable. Provisioned concurrency helped significantly.", created_at: 1.day.ago },
    { user: :charlie, commentable: submissions[:vercel_edge_functions], body: "Edge functions tutorial is great. The global low-latency use cases are well explained.", created_at: 1.day.ago }
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
  # Generate many upvotes - each comment gets 2-5 upvotes from different users
  all_user_keys = %i[alice bob charlie diana eve frank grace henry ivy jack kate liam mia]
  upvote_defs = []
  comment_defs.each_with_index do |comment_attrs, idx|
    comment = comments[idx]
    next unless comment
    
    # Skip upvoting own comments
    comment_author = comment_attrs[:user]
    available_upvoters = all_user_keys - [comment_author]
    
    # Each comment gets 2-5 upvotes
    num_upvotes = [2, 3, 4, 5].sample
    available_upvoters.shuffle.first(num_upvotes).each do |upvoter|
      upvote_defs << { user: upvoter, comment: comment }
    end
  end
  
  # Also add some specific meaningful upvotes
  upvote_defs += [
    { user: :bob, comment: comments[0] },
    { user: :charlie, comment: comments[0] },
    { user: :diana, comment: comments[0] },
    { user: :alice, comment: comments[1] },
    { user: :bob, comment: comments[1] },
    { user: :alice, comment: comments[2] },
    { user: :diana, comment: comments[2] },
    { user: :diana, comment: comments[4] },
    { user: :eve, comment: comments[4] },
    { user: :grace, comment: comments[6] },
    { user: :ivy, comment: comments[6] },
    { user: :charlie, comment: comments[6] },
    { user: :henry, comment: comments[8] },
    { user: :bob, comment: comments[8] },
    { user: :jack, comment: comments[10] },
    { user: :kate, comment: comments[11] },
    { user: :diana, comment: comments[11] },
    { user: :liam, comment: comments[12] },
    { user: :eve, comment: comments[12] },
    { user: :mia, comment: comments[13] },
    { user: :bob, comment: comments[13] },
    { user: :charlie, comment: comments[14] },
    { user: :ivy, comment: comments[15] },
    { user: :charlie, comment: comments[15] },
    { user: :bob, comment: comments[17] },
    { user: :liam, comment: comments[18] },
    { user: :kate, comment: comments[19] },
    { user: :diana, comment: comments[19] },
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
  
  # Remove duplicates
  upvote_defs.uniq! { |uv| [uv[:user], uv[:comment].id] }

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
