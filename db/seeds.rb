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
    { key: :frank, email: "frank@example.com", username: "frank_product", bio: "PM curating tools for the team." }
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

  # Tags (typed + parent/child)
  log_step "Creating tags"
  tags = {}
  tag_defs = [
    { key: :dev, name: "development", type: :category },
    { key: :ai, name: "ai", type: :category },
    { key: :frontend, name: "frontend", type: :category, parent: :dev },
    { key: :backend, name: "backend", type: :category, parent: :dev },
    { key: :devops, name: "devops", type: :category },
    { key: :data, name: "data", type: :category },
    { key: :security, name: "security", type: :category, parent: :devops },
    { key: :testing, name: "testing", type: :category, parent: :dev },
    { key: :productivity, name: "productivity", type: :category, parent: :dev },
    { key: :ruby, name: "ruby", type: :language },
    { key: :rails, name: "rails", type: :framework, parent: :ruby },
    { key: :javascript, name: "javascript", type: :language },
    { key: :react, name: "react", type: :framework, parent: :javascript },
    { key: :python, name: "python", type: :language },
    { key: :django, name: "django", type: :framework, parent: :python },
    { key: :kubernetes, name: "kubernetes", type: :platform, parent: :devops },
    { key: :postgres, name: "postgresql", type: :platform, parent: :data },
    { key: :llm, name: "llm", type: :library, parent: :ai },
    { key: :observability, name: "observability", type: :platform, parent: :devops }
  ]

  tag_defs.each do |attrs|
    tag = Tag.find_or_initialize_by(tag_name: attrs[:name].downcase)
    tag.tag_description = attrs[:description]
    tag.tag_type = attrs[:type]
    tag.parent = tags[attrs[:parent]] if attrs[:parent]
    tag.save!
    tags[attrs[:key]] = tag
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
    { key: :react, name: "React", url: "https://react.dev", desc: "Component-based UI library.", note: "Used for comparison to Hotwire.", tags: %i[react frontend javascript], created_at: 16.days.ago }
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
ensure
  Tool.set_callback(:create, :after, :enqueue_discovery_job) if tool_callback_disabled
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
    { user: :frank, tool: :rails, upvote: true, read_at: 2.days.ago }
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
    { user: :eve, submission: :observability_stack, upvote: true, favorite: true, read_at: 12.hours.ago }
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
    { user: :frank, followable: lists[:rails_stack] }
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
    { user: :alice, commentable: submissions[:react_vs_turbo], body: "Benchmarks were super helpful.", created_at: 1.day.ago, parent: 1 }
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
    { user: :diana, comment: comments[4] }
  ]

  upvote_defs.each do |attrs|
    CommentUpvote.find_or_create_by!(user: users[attrs[:user]], comment: attrs[:comment])
  end
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
