# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data (optional - comment out if you want to preserve data)
# Destroy in order to respect foreign key constraints
puts "Clearing existing data..."
CommentUpvote.destroy_all
UserTool.destroy_all
ListTool.destroy_all
ToolTag.destroy_all
Comment.destroy_all
Tool.destroy_all
List.destroy_all
Tag.destroy_all
User.destroy_all

# Create Users
puts "Creating users..."
users = []

# Create some active users with different roles
users << User.create!(
  email: "alice@example.com",
  password: "password123",
  username: "alice_dev",
  user_type: 0,
  user_status: 0,
  user_bio: "Full-stack developer passionate about developer tools and productivity. Always on the lookout for the next great tool!"
)

users << User.create!(
  email: "bob@example.com",
  password: "password123",
  username: "bob_codes",
  user_type: 0,
  user_status: 0,
  user_bio: "Backend engineer. Love exploring new frameworks and libraries."
)

users << User.create!(
  email: "charlie@example.com",
  password: "password123",
  username: "charlie_ui",
  user_type: 0,
  user_status: 0,
  user_bio: "Frontend developer and UI/UX enthusiast. Sharing tools that make design and development easier."
)

users << User.create!(
  email: "diana@example.com",
  password: "password123",
  username: "diana_ops",
  user_type: 0,
  user_status: 0,
  user_bio: "DevOps engineer. Interested in infrastructure, monitoring, and automation tools."
)

users << User.create!(
  email: "eve@example.com",
  password: "password123",
  username: "eve_data",
  user_type: 0,
  user_status: 0,
  user_bio: "Data scientist and ML engineer. Curating tools for data analysis and machine learning."
)

# Soft-deleted user to validate historical associations remain intact
deleted_user = User.create!(
  email: "ghost@example.com",
  password: "password123",
  username: "ghost_user",
  user_type: 0,
  user_status: 0,
  user_bio: "Former user whose content remains for historical context. Soft-deleted to verify associations."
)
deleted_user.soft_delete! # Applies anonymized email/username and marks user_status as deleted
users << deleted_user

# Create Tags
puts "Creating tags..."
tags = {}

# Technology categories
tags[:ruby] = Tag.create!(tag_name: "Ruby", tag_description: "Ruby programming language and ecosystem", tag_type: 0)
tags[:rails] = Tag.create!(tag_name: "Rails", tag_description: "Ruby on Rails framework", tag_type: 0, parent: tags[:ruby])
tags[:javascript] = Tag.create!(tag_name: "JavaScript", tag_description: "JavaScript programming language", tag_type: 0)
tags[:react] = Tag.create!(tag_name: "React", tag_description: "React library for building user interfaces", tag_type: 0, parent: tags[:javascript])
tags[:python] = Tag.create!(tag_name: "Python", tag_description: "Python programming language", tag_type: 0)
tags[:devops] = Tag.create!(tag_name: "DevOps", tag_description: "DevOps and infrastructure tools", tag_type: 0)
tags[:database] = Tag.create!(tag_name: "Database", tag_description: "Database tools and utilities", tag_type: 0)
tags[:testing] = Tag.create!(tag_name: "Testing", tag_description: "Testing frameworks and tools", tag_type: 0)
tags[:productivity] = Tag.create!(tag_name: "Productivity", tag_description: "Tools to improve developer productivity", tag_type: 0)
tags[:api] = Tag.create!(tag_name: "API", tag_description: "API development and testing tools", tag_type: 0)
tags[:git] = Tag.create!(tag_name: "Git", tag_description: "Version control and Git tools", tag_type: 0)
tags[:docker] = Tag.create!(tag_name: "Docker", tag_description: "Containerization tools", tag_type: 0, parent: tags[:devops])
tags[:security] = Tag.create!(tag_name: "Security", tag_description: "Security scanning and auditing utilities", tag_type: 0, parent: tags[:devops])
tags[:ci_cd] = Tag.create!(tag_name: "CI/CD", tag_description: "Continuous integration and delivery automation", tag_type: 0, parent: tags[:devops])
tags[:observability] = Tag.create!(tag_name: "Observability", tag_description: "Monitoring, metrics, and tracing", tag_type: 0, parent: tags[:devops])

# Create Tools
puts "Creating tools..."
tools = []

# Ruby/Rails tools
tools << Tool.create!(
  user: users[0],
  tool_name: "RuboCop",
  tool_description: "A Ruby static code analyzer and formatter. Out of the box it will enforce many of the guidelines outlined in the community Ruby Style Guide.",
  tool_url: "https://rubocop.org",
  author_note: "Essential for maintaining consistent Ruby code style. Integrates well with most editors.",
  visibility: 0,
  created_at: 2.days.ago
)

tools << Tool.create!(
  user: users[0],
  tool_name: "SimpleCov",
  tool_description: "Code coverage for Ruby with a powerful configuration library and automatic merging of coverage across test suites.",
  tool_url: "https://github.com/simplecov-ruby/simplecov",
  author_note: "Great for tracking test coverage in Rails projects. Easy to set up and provides detailed HTML reports.",
  visibility: 0,
  created_at: 5.days.ago
)

tools << Tool.create!(
  user: users[1],
  tool_name: "RSpec",
  tool_description: "Behaviour Driven Development for Ruby. Making TDD productive and fun.",
  tool_url: "https://rspec.info",
  author_note: "My go-to testing framework for Ruby. Excellent documentation and great community support.",
  visibility: 0,
  created_at: 1.week.ago
)

# JavaScript/React tools
tools << Tool.create!(
  user: users[2],
  tool_name: "ESLint",
  tool_description: "Find and fix problems in your JavaScript code. Pluggable JavaScript linter.",
  tool_url: "https://eslint.org",
  author_note: "Must-have for any JavaScript project. Highly configurable and supports modern JS features.",
  visibility: 0,
  created_at: 3.days.ago
)

tools << Tool.create!(
  user: users[2],
  tool_name: "React DevTools",
  tool_description: "Browser extension that allows inspection of React component hierarchies in the Chrome and Firefox Developer Tools.",
  tool_url: "https://react.dev/learn/react-developer-tools",
  author_note: "Invaluable for debugging React applications. Shows component props, state, and hooks.",
  visibility: 0,
  created_at: 1.day.ago
)

tools << Tool.create!(
  user: users[2],
  tool_name: "Vite",
  tool_description: "Next generation frontend tooling. It's fast!",
  tool_url: "https://vitejs.dev",
  author_note: "Lightning-fast build tool. Replaced Webpack in all my projects. The dev server is incredibly fast.",
  visibility: 0,
  created_at: 4.days.ago
)

# DevOps tools
tools << Tool.create!(
  user: users[3],
  tool_name: "Docker Compose",
  tool_description: "Define and run multi-container Docker applications. With Compose, you use a YAML file to configure your application's services.",
  tool_url: "https://docs.docker.com/compose/",
  author_note: "Makes managing multi-container applications a breeze. Essential for local development environments.",
  visibility: 0,
  created_at: 6.days.ago
)

tools << Tool.create!(
  user: users[3],
  tool_name: "Terraform",
  tool_description: "Infrastructure as Code tool for building, changing, and versioning infrastructure safely and efficiently.",
  tool_url: "https://www.terraform.io",
  author_note: "Game-changer for infrastructure management. Version control your infrastructure and deploy with confidence.",
  visibility: 0,
  created_at: 1.week.ago
)

tools << Tool.create!(
  user: users[3],
  tool_name: "Kubernetes",
  tool_description: "Production-grade container orchestration. Automates deployment, scaling, and management of containerized applications.",
  tool_url: "https://kubernetes.io",
  author_note: "Industry standard for container orchestration. Steep learning curve but incredibly powerful.",
  visibility: 0,
  created_at: 2.weeks.ago
)

# Database tools
tools << Tool.create!(
  user: users[1],
  tool_name: "pgAdmin",
  tool_description: "Comprehensive PostgreSQL administration and development platform.",
  tool_url: "https://www.pgadmin.org",
  author_note: "Great GUI for PostgreSQL. Makes database management much easier than command line.",
  visibility: 0,
  created_at: 3.days.ago
)

tools << Tool.create!(
  user: users[0],
  tool_name: "Sequel Pro",
  tool_description: "Fast, easy-to-use Mac database management application for working with MySQL databases.",
  tool_url: "https://www.sequelpro.com",
  author_note: "Simple and intuitive MySQL client for Mac. Unfortunately no longer actively maintained, but still works great.",
  visibility: 0,
  created_at: 1.week.ago
)

# Productivity tools
tools << Tool.create!(
  user: users[0],
  tool_name: "GitHub Copilot",
  tool_description: "Your AI pair programmer. Get suggestions for whole lines or entire functions right inside your editor.",
  tool_url: "https://github.com/features/copilot",
  author_note: "Controversial but undeniably useful. Helps with boilerplate and repetitive code. Use responsibly!",
  visibility: 0,
  created_at: 2.days.ago
)

tools << Tool.create!(
  user: users[2],
  tool_name: "Figma",
  tool_description: "Collaborative interface design tool. Design, prototype, and gather feedback all in one place.",
  tool_url: "https://www.figma.com",
  author_note: "Industry standard for UI/UX design. Great collaboration features and excellent developer handoff.",
  visibility: 0,
  created_at: 5.days.ago
)

# API tools
tools << Tool.create!(
  user: users[1],
  tool_name: "Postman",
  tool_description: "Complete API development environment. Test, document, and share APIs.",
  tool_url: "https://www.postman.com",
  author_note: "Essential for API development and testing. Great for team collaboration and API documentation.",
  visibility: 0,
  created_at: 4.days.ago
)

tools << Tool.create!(
  user: users[0],
  tool_name: "Insomnia",
  tool_description: "The Collaborative API Design Platform. Design, debug, and test APIs with your team.",
  tool_url: "https://insomnia.rest",
  author_note: "Lightweight alternative to Postman. Great UI and fast performance. My personal favorite.",
  visibility: 0,
  created_at: 1.day.ago
)

# Git tools
tools << Tool.create!(
  user: users[0],
  tool_name: "GitHub Desktop",
  tool_description: "Simple collaboration from your desktop. Extend your GitHub workflow beyond your browser.",
  tool_url: "https://desktop.github.com",
  author_note: "Perfect for Git beginners or when you want a visual interface. Makes Git operations more intuitive.",
  visibility: 0,
  created_at: 3.days.ago
)

tools << Tool.create!(
  user: users[0],
  tool_name: "Pry",
  tool_description: "A runtime developer console and IRB alternative with powerful introspection tools.",
  tool_url: "https://pry.github.io",
  author_note: "Supercharges Ruby debugging with better navigation and context-aware features.",
  visibility: 0,
  created_at: 2.days.ago + 3.hours
)

tools << Tool.create!(
  user: users[0],
  tool_name: "Brakeman",
  tool_description: "Static analysis security scanner for Ruby on Rails applications.",
  tool_url: "https://brakemanscanner.org",
  author_note: "Fast way to catch Rails-specific security issues before code review.",
  visibility: 0,
  created_at: 1.week.ago + 1.day
)

tools << Tool.create!(
  user: users[1],
  tool_name: "Bundler Audit",
  tool_description: "Patch-level verification for Bundler to check for vulnerable Ruby gems.",
  tool_url: "https://github.com/rubysec/bundler-audit",
  author_note: "Keeps Gemfile.lock honest by flagging known CVEs quickly.",
  visibility: 0,
  created_at: 5.days.ago + 6.hours
)

tools << Tool.create!(
  user: users[2],
  tool_name: "Prettier",
  tool_description: "Opinionated code formatter for JavaScript, TypeScript, and more.",
  tool_url: "https://prettier.io",
  author_note: "Removes bikeshedding from code style debates; pairs nicely with ESLint.",
  visibility: 0,
  created_at: 2.days.ago + 5.hours
)

tools << Tool.create!(
  user: users[2],
  tool_name: "Cypress",
  tool_description: "End-to-end testing framework for web applications with fast feedback.",
  tool_url: "https://www.cypress.io",
  author_note: "Great DX with time-travel debugging and deterministic runs.",
  visibility: 0,
  created_at: 6.days.ago + 8.hours
)

tools << Tool.create!(
  user: users[2],
  tool_name: "Storybook",
  tool_description: "UI component workshop for building and documenting components in isolation.",
  tool_url: "https://storybook.js.org",
  author_note: "Perfect for visual regression workflows and design system work.",
  visibility: 0,
  created_at: 4.days.ago + 2.hours
)

tools << Tool.create!(
  user: users[3],
  tool_name: "GitHub Actions",
  tool_description: "CI/CD platform natively integrated with GitHub repositories.",
  tool_url: "https://github.com/features/actions",
  author_note: "Great default for pipelines; reusable workflows keep repos DRY.",
  visibility: 0,
  created_at: 3.days.ago + 4.hours
)

tools << Tool.create!(
  user: users[3],
  tool_name: "Argo CD",
  tool_description: "Declarative, GitOps continuous delivery for Kubernetes.",
  tool_url: "https://argo-cd.readthedocs.io",
  author_note: "Reliable Kubernetes deployments with Git as the source of truth.",
  visibility: 0,
  created_at: 1.week.ago + 2.days
)

tools << Tool.create!(
  user: users[3],
  tool_name: "Grafana",
  tool_description: "Open-source analytics and monitoring solution for every database.",
  tool_url: "https://grafana.com",
  author_note: "Flexible dashboards for metrics and logs; pairs well with Prometheus.",
  visibility: 0,
  created_at: 5.days.ago + 1.hour
)

tools << Tool.create!(
  user: users[3],
  tool_name: "Prometheus",
  tool_description: "Monitoring system and time series database for metrics.",
  tool_url: "https://prometheus.io",
  author_note: "Battle-tested metrics store with powerful PromQL queries.",
  visibility: 0,
  created_at: 6.days.ago + 3.hours
)

tools << Tool.create!(
  user: users[1],
  tool_name: "DBeaver",
  tool_description: "Universal database tool supporting all major DBs with ER diagrams.",
  tool_url: "https://dbeaver.io",
  author_note: "Cross-platform and handles odd drivers well; my go-to DB browser.",
  visibility: 0,
  created_at: 2.days.ago + 6.hours
)

tools << Tool.create!(
  user: users[0],
  tool_name: "TablePlus",
  tool_description: "Modern, native database GUI for relational and NoSQL databases.",
  tool_url: "https://tableplus.com",
  author_note: "Fast keyboard shortcuts and great diff UI for schema changes.",
  visibility: 0,
  created_at: 4.days.ago + 5.hours
)

tools << Tool.create!(
  user: users[1],
  tool_name: "Hoppscotch",
  tool_description: "Lightweight open-source API request builder.",
  tool_url: "https://hoppscotch.io",
  author_note: "Quicker than Postman for quick checks; runs well in browser.",
  visibility: 0,
  created_at: 1.day.ago + 6.hours
)

tools << Tool.create!(
  user: users[0],
  tool_name: "HTTPie",
  tool_description: "User-friendly HTTP client CLI and desktop app.",
  tool_url: "https://httpie.io",
  author_note: "Readable CLI requests with colorized responses; great for demos.",
  visibility: 0,
  created_at: 2.days.ago + 7.hours
)

tools << Tool.create!(
  user: users[2],
  tool_name: "Notion",
  tool_description: "All-in-one workspace for docs, tasks, and databases.",
  tool_url: "https://www.notion.so",
  author_note: "Solid for lightweight product specs and team docs.",
  visibility: 0,
  created_at: 3.days.ago + 6.hours
)

tools << Tool.create!(
  user: users[0],
  tool_name: "Raycast",
  tool_description: "Fast launcher and productivity platform with an extensions store.",
  tool_url: "https://www.raycast.com",
  author_note: "Great for speeding up daily workflows with custom commands.",
  visibility: 0,
  created_at: 1.day.ago + 4.hours
)

tools << Tool.create!(
  user: deleted_user,
  tool_name: "OWASP ZAP",
  tool_description: "Full-featured security scanner for web applications.",
  tool_url: "https://www.zaproxy.org",
  author_note: "Reliable baseline DAST scanner; good for CI smoke security checks.",
  visibility: 0,
  created_at: 5.days.ago + 2.hours
)

tools << Tool.create!(
  user: deleted_user,
  tool_name: "Trivy",
  tool_description: "Comprehensive, easy-to-use vulnerability scanner for containers and dependencies.",
  tool_url: "https://aquasecurity.github.io/trivy",
  author_note: "Fast container and IaC scanning that fits well into CI pipelines.",
  visibility: 0,
  created_at: 4.days.ago + 1.hour
)

# Associate tags with tools
puts "Associating tags with tools..."
ToolTag.create!(tool: tools[0], tag: tags[:ruby]) # RuboCop
ToolTag.create!(tool: tools[0], tag: tags[:testing])
ToolTag.create!(tool: tools[1], tag: tags[:ruby]) # SimpleCov
ToolTag.create!(tool: tools[1], tag: tags[:testing])
ToolTag.create!(tool: tools[2], tag: tags[:ruby]) # RSpec
ToolTag.create!(tool: tools[2], tag: tags[:testing])
ToolTag.create!(tool: tools[3], tag: tags[:javascript]) # ESLint
ToolTag.create!(tool: tools[3], tag: tags[:productivity])
ToolTag.create!(tool: tools[4], tag: tags[:react]) # React DevTools
ToolTag.create!(tool: tools[4], tag: tags[:javascript])
ToolTag.create!(tool: tools[5], tag: tags[:javascript]) # Vite
ToolTag.create!(tool: tools[5], tag: tags[:productivity])
ToolTag.create!(tool: tools[6], tag: tags[:docker]) # Docker Compose
ToolTag.create!(tool: tools[6], tag: tags[:devops])
ToolTag.create!(tool: tools[7], tag: tags[:devops]) # Terraform
ToolTag.create!(tool: tools[8], tag: tags[:devops]) # Kubernetes
ToolTag.create!(tool: tools[8], tag: tags[:docker])
ToolTag.create!(tool: tools[9], tag: tags[:database]) # pgAdmin
ToolTag.create!(tool: tools[10], tag: tags[:database]) # Sequel Pro
ToolTag.create!(tool: tools[11], tag: tags[:productivity]) # GitHub Copilot
ToolTag.create!(tool: tools[11], tag: tags[:git])
ToolTag.create!(tool: tools[12], tag: tags[:productivity]) # Figma
ToolTag.create!(tool: tools[13], tag: tags[:api]) # Postman
ToolTag.create!(tool: tools[14], tag: tags[:api]) # Insomnia
ToolTag.create!(tool: tools[15], tag: tags[:git]) # GitHub Desktop
ToolTag.create!(tool: tools[16], tag: tags[:ruby]) # Pry
ToolTag.create!(tool: tools[17], tag: tags[:ruby]) # Brakeman
ToolTag.create!(tool: tools[17], tag: tags[:security])
ToolTag.create!(tool: tools[18], tag: tags[:ruby]) # Bundler Audit
ToolTag.create!(tool: tools[18], tag: tags[:security])
ToolTag.create!(tool: tools[19], tag: tags[:javascript]) # Prettier
ToolTag.create!(tool: tools[19], tag: tags[:productivity])
ToolTag.create!(tool: tools[20], tag: tags[:javascript]) # Cypress
ToolTag.create!(tool: tools[20], tag: tags[:testing])
ToolTag.create!(tool: tools[21], tag: tags[:react]) # Storybook
ToolTag.create!(tool: tools[21], tag: tags[:javascript])
ToolTag.create!(tool: tools[22], tag: tags[:git]) # GitHub Actions
ToolTag.create!(tool: tools[22], tag: tags[:ci_cd])
ToolTag.create!(tool: tools[22], tag: tags[:devops])
ToolTag.create!(tool: tools[23], tag: tags[:devops]) # Argo CD
ToolTag.create!(tool: tools[23], tag: tags[:docker])
ToolTag.create!(tool: tools[23], tag: tags[:ci_cd])
ToolTag.create!(tool: tools[24], tag: tags[:observability]) # Grafana
ToolTag.create!(tool: tools[24], tag: tags[:devops])
ToolTag.create!(tool: tools[25], tag: tags[:observability]) # Prometheus
ToolTag.create!(tool: tools[25], tag: tags[:devops])
ToolTag.create!(tool: tools[26], tag: tags[:database]) # DBeaver
ToolTag.create!(tool: tools[27], tag: tags[:database]) # TablePlus
ToolTag.create!(tool: tools[28], tag: tags[:api]) # Hoppscotch
ToolTag.create!(tool: tools[29], tag: tags[:api]) # HTTPie
ToolTag.create!(tool: tools[30], tag: tags[:productivity]) # Notion
ToolTag.create!(tool: tools[31], tag: tags[:productivity]) # Raycast
ToolTag.create!(tool: tools[32], tag: tags[:security]) # OWASP ZAP
ToolTag.create!(tool: tools[32], tag: tags[:devops])
ToolTag.create!(tool: tools[33], tag: tags[:security]) # Trivy
ToolTag.create!(tool: tools[33], tag: tags[:docker])
ToolTag.create!(tool: tools[33], tag: tags[:devops])

# Create Lists
puts "Creating lists..."
lists = []

lists << List.create!(
  user: users[0],
  list_name: "Essential Ruby Tools",
  list_type: 0,
  visibility: 0,
  created_at: 3.days.ago
)

lists << List.create!(
  user: users[2],
  list_name: "Frontend Development Stack",
  list_type: 0,
  visibility: 0,
  created_at: 2.days.ago
)

lists << List.create!(
  user: users[3],
  list_name: "DevOps Essentials",
  list_type: 0,
  visibility: 0,
  created_at: 1.week.ago
)

lists << List.create!(
  user: users[0],
  list_name: "My Favorites",
  list_type: 0,
  visibility: 1, # Unlisted/private
  created_at: 1.day.ago
)

lists << List.create!(
  user: users[1],
  list_name: "Database Workbench",
  list_type: 0,
  visibility: 0,
  created_at: 2.days.ago
)

lists << List.create!(
  user: deleted_user,
  list_name: "Archived Security Picks",
  list_type: 0,
  visibility: 1, # Unlisted/private to reflect legacy content
  created_at: 3.days.ago
)

# Add tools to lists
puts "Adding tools to lists..."
ListTool.create!(list: lists[0], tool: tools[0]) # RuboCop
ListTool.create!(list: lists[0], tool: tools[1]) # SimpleCov
ListTool.create!(list: lists[0], tool: tools[2]) # RSpec

ListTool.create!(list: lists[1], tool: tools[3]) # ESLint
ListTool.create!(list: lists[1], tool: tools[4]) # React DevTools
ListTool.create!(list: lists[1], tool: tools[5]) # Vite
ListTool.create!(list: lists[1], tool: tools[12]) # Figma

ListTool.create!(list: lists[2], tool: tools[6]) # Docker Compose
ListTool.create!(list: lists[2], tool: tools[7]) # Terraform
ListTool.create!(list: lists[2], tool: tools[8]) # Kubernetes

ListTool.create!(list: lists[3], tool: tools[11]) # GitHub Copilot
ListTool.create!(list: lists[3], tool: tools[14]) # Insomnia
ListTool.create!(list: lists[3], tool: tools[15]) # GitHub Desktop
ListTool.create!(list: lists[0], tool: tools[16]) # Pry
ListTool.create!(list: lists[0], tool: tools[17]) # Brakeman
ListTool.create!(list: lists[0], tool: tools[18]) # Bundler Audit
ListTool.create!(list: lists[1], tool: tools[19]) # Prettier
ListTool.create!(list: lists[1], tool: tools[20]) # Cypress
ListTool.create!(list: lists[1], tool: tools[21]) # Storybook
ListTool.create!(list: lists[2], tool: tools[22]) # GitHub Actions
ListTool.create!(list: lists[2], tool: tools[23]) # Argo CD
ListTool.create!(list: lists[2], tool: tools[24]) # Grafana
ListTool.create!(list: lists[2], tool: tools[25]) # Prometheus
ListTool.create!(list: lists[3], tool: tools[28]) # Hoppscotch
ListTool.create!(list: lists[3], tool: tools[29]) # HTTPie
ListTool.create!(list: lists[3], tool: tools[31]) # Raycast
ListTool.create!(list: lists[4], tool: tools[9]) # pgAdmin in Database Workbench
ListTool.create!(list: lists[4], tool: tools[10]) # Sequel Pro in Database Workbench
ListTool.create!(list: lists[4], tool: tools[26]) # DBeaver
ListTool.create!(list: lists[4], tool: tools[27]) # TablePlus
ListTool.create!(list: lists[5], tool: tools[32]) # OWASP ZAP in Archived Security Picks
ListTool.create!(list: lists[5], tool: tools[33]) # Trivy in Archived Security Picks

# Create Comments (with some threaded discussions)
puts "Creating comments..."
comments = []

# Comments on RuboCop (tool 0)
comments << Comment.create!(
  tool: tools[0],
  user: users[1],
  comment: "Great tool! I've been using it for years. The auto-fix feature saves so much time.",
  comment_type: 0,
  visibility: 0,
  created_at: 2.days.ago
)

comments << Comment.create!(
  tool: tools[0],
  user: users[2],
  comment: "How do you configure it for Rails projects? I'm having trouble with some style rules.",
  comment_type: 0,
  visibility: 0,
  created_at: 1.day.ago
)

# Reply to the question
comments << Comment.create!(
  tool: tools[0],
  user: users[0],
  comment: "I recommend using the rubocop-rails gem and starting with the default Rails configuration. You can then customize from there.",
  comment_type: 0,
  visibility: 0,
  parent: comments[1],
  created_at: 1.day.ago + 2.hours
)

# Comments on React DevTools (tool 4)
comments << Comment.create!(
  tool: tools[4],
  user: users[0],
  comment: "This is a lifesaver for debugging React apps. The component tree view is incredibly useful.",
  comment_type: 0,
  visibility: 0,
  created_at: 1.day.ago
)

comments << Comment.create!(
  tool: tools[4],
  user: users[1],
  comment: "Does it work with React Native as well?",
  comment_type: 0,
  visibility: 0,
  created_at: 12.hours.ago
)

comments << Comment.create!(
  tool: tools[4],
  user: users[2],
  comment: "Yes! React Native Debugger includes React DevTools. Works great for mobile development.",
  comment_type: 0,
  visibility: 0,
  parent: comments[4],
  solved: true,
  created_at: 10.hours.ago
)

# Comments on Vite (tool 5)
comments << Comment.create!(
  tool: tools[5],
  user: users[3],
  comment: "Switched from Webpack to Vite last month. The dev server startup time is incredible!",
  comment_type: 0,
  visibility: 0,
  created_at: 4.days.ago
)

comments << Comment.create!(
  tool: tools[5],
  user: users[2],
  comment: "The HMR (Hot Module Replacement) is also much faster. Really improved my development workflow.",
  comment_type: 0,
  visibility: 0,
  created_at: 3.days.ago
)

# Comments on Docker Compose (tool 6)
comments << Comment.create!(
  tool: tools[6],
  user: users[0],
  comment: "Essential for local development. Makes it so easy to spin up complex environments.",
  comment_type: 0,
  visibility: 0,
  created_at: 6.days.ago
)

comments << Comment.create!(
  tool: tools[19],
  user: users[2],
  comment: "Prettier plus ESLint with the right config keeps our PRs clean.",
  comment_type: 0,
  visibility: 0,
  created_at: 1.day.ago + 3.hours
)

comments << Comment.create!(
  tool: tools[20],
  user: users[0],
  comment: "Cypress Component Testing has been great for catching regressions in UI primitives.",
  comment_type: 0,
  visibility: 0,
  created_at: 2.days.ago + 5.hours
)

comments << Comment.create!(
  tool: tools[22],
  user: users[3],
  comment: "Reusable workflows help us keep pipeline logic consistent across repos.",
  comment_type: 0,
  visibility: 0,
  created_at: 1.day.ago + 1.hour
)

comments << Comment.create!(
  tool: tools[22],
  user: users[1],
  comment: "Do you cache Ruby gems between jobs? Curious about speed gains.",
  comment_type: 0,
  visibility: 0,
  created_at: 12.hours.ago
)

comments << Comment.create!(
  tool: tools[22],
  user: users[3],
  comment: "Yes, we cache bundler and node_modules; shaved off ~2 minutes per run.",
  comment_type: 0,
  visibility: 0,
  parent: comments.last,
  created_at: 10.hours.ago
)

comments << Comment.create!(
  tool: tools[24],
  user: users[3],
  comment: "Grafana Loki integration is solid if you need logs and metrics in one place.",
  comment_type: 0,
  visibility: 0,
  created_at: 3.days.ago + 1.hour
)

comments << Comment.create!(
  tool: tools[28],
  user: users[0],
  comment: "Hoppscotch is great for quick REST calls when I don't want to open Postman.",
  comment_type: 0,
  visibility: 0,
  created_at: 1.day.ago + 2.hours
)

comments << Comment.create!(
  tool: tools[29],
  user: users[1],
  comment: "HTTPie syntax reads like English; handy for onboarding juniors to APIs.",
  comment_type: 0,
  visibility: 0,
  created_at: 1.day.ago + 5.hours
)

comments << Comment.create!(
  tool: tools[31],
  user: users[2],
  comment: "Raycast snippets and script commands save me so many context switches.",
  comment_type: 0,
  visibility: 0,
  created_at: 8.hours.ago
)

comments << Comment.create!(
  tool: tools[32],
  user: deleted_user,
  comment: "Used ZAP for nightly scans before we migrated; keeping results around for reference.",
  comment_type: 0,
  visibility: 0,
  created_at: 2.days.ago + 2.hours
)

comments << Comment.create!(
  tool: tools[33],
  user: deleted_user,
  comment: "Trivy catches base-image CVEs early in CI. Flagging a noisy rule set that needs tuning.",
  comment_type: :flag,
  visibility: 0,
  created_at: 1.day.ago + 7.hours
)

comments << Comment.create!(
  tool: tools[8],
  user: deleted_user,
  comment: "BUG: Kubernetes manifests generator sometimes emits invalid apiVersions in our setup.",
  comment_type: :bug,
  visibility: 0,
  created_at: 3.days.ago + 4.hours
)

comments << Comment.create!(
  tool: tools[22],
  user: users[0],
  comment: "Flagging the noisy rule mentioned above—can we scope Trivy to prod images only?",
  comment_type: :flag,
  visibility: 0,
  parent: comments[-2],
  created_at: 1.day.ago + 6.hours
)

# Create UserTool interactions (upvotes, favorites, subscriptions)
puts "Creating user interactions..."

# Alice upvotes and favorites several tools
UserTool.create!(
  user: users[0],
  tool: tools[3], # ESLint
  upvote: true,
  favorite: true,
  read_at: 2.days.ago
)

UserTool.create!(
  user: users[0],
  tool: tools[5], # Vite
  upvote: true,
  favorite: true,
  subscribe: true,
  read_at: 4.days.ago
)

UserTool.create!(
  user: users[0],
  tool: tools[14], # Insomnia
  upvote: true,
  favorite: true,
  read_at: 1.day.ago
)

# Bob upvotes and subscribes to some tools
UserTool.create!(
  user: users[1],
  tool: tools[0], # RuboCop
  upvote: true,
  subscribe: true,
  read_at: 2.days.ago
)

UserTool.create!(
  user: users[1],
  tool: tools[2], # RSpec
  upvote: true,
  favorite: true,
  read_at: 1.week.ago
)

UserTool.create!(
  user: users[1],
  tool: tools[9], # pgAdmin
  upvote: true,
  read_at: 3.days.ago
)

# Charlie upvotes React and frontend tools
UserTool.create!(
  user: users[2],
  tool: tools[4], # React DevTools
  upvote: true,
  favorite: true,
  subscribe: true,
  read_at: 1.day.ago
)

UserTool.create!(
  user: users[2],
  tool: tools[5], # Vite
  upvote: true,
  favorite: true,
  read_at: 4.days.ago
)

UserTool.create!(
  user: users[2],
  tool: tools[12], # Figma
  upvote: true,
  read_at: 5.days.ago
)

# Diana upvotes DevOps tools
UserTool.create!(
  user: users[3],
  tool: tools[6], # Docker Compose
  upvote: true,
  favorite: true,
  read_at: 6.days.ago
)

UserTool.create!(
  user: users[3],
  tool: tools[7], # Terraform
  upvote: true,
  subscribe: true,
  read_at: 1.week.ago
)

UserTool.create!(
  user: users[3],
  tool: tools[8], # Kubernetes
  upvote: true,
  favorite: true,
  read_at: 2.weeks.ago
)

UserTool.create!(
  user: users[2],
  tool: tools[19], # Prettier
  upvote: true,
  favorite: true,
  read_at: 1.day.ago + 2.hours
)

UserTool.create!(
  user: users[2],
  tool: tools[21], # Storybook
  upvote: true,
  subscribe: true,
  read_at: 2.days.ago + 1.hour
)

UserTool.create!(
  user: users[0],
  tool: tools[20], # Cypress
  upvote: true,
  subscribe: true,
  read_at: 2.days.ago + 6.hours
)

UserTool.create!(
  user: users[3],
  tool: tools[22], # GitHub Actions
  upvote: true,
  favorite: true,
  read_at: 1.day.ago + 2.hours
)

UserTool.create!(
  user: users[3],
  tool: tools[23], # Argo CD
  upvote: true,
  subscribe: true,
  read_at: 3.days.ago
)

UserTool.create!(
  user: users[3],
  tool: tools[24], # Grafana
  upvote: true,
  favorite: true,
  read_at: 2.days.ago + 3.hours
)

UserTool.create!(
  user: users[3],
  tool: tools[25], # Prometheus
  upvote: true,
  read_at: 2.days.ago + 4.hours
)

UserTool.create!(
  user: users[1],
  tool: tools[26], # DBeaver
  upvote: true,
  favorite: true,
  read_at: 2.days.ago + 6.hours
)

UserTool.create!(
  user: users[0],
  tool: tools[27], # TablePlus
  upvote: true,
  favorite: true,
  read_at: 4.days.ago + 5.hours
)

UserTool.create!(
  user: users[0],
  tool: tools[28], # Hoppscotch
  upvote: true,
  subscribe: true,
  read_at: 1.day.ago + 2.hours
)

UserTool.create!(
  user: users[1],
  tool: tools[29], # HTTPie
  upvote: true,
  favorite: true,
  read_at: 1.day.ago + 5.hours
)

UserTool.create!(
  user: users[2],
  tool: tools[30], # Notion
  upvote: true,
  favorite: true,
  read_at: 3.days.ago + 6.hours
)

UserTool.create!(
  user: users[0],
  tool: tools[31], # Raycast
  upvote: true,
  favorite: true,
  subscribe: true,
  read_at: 1.day.ago + 4.hours
)

# Create Comment Upvotes
puts "Creating comment upvotes..."
CommentUpvote.create!(comment: comments[0], user: users[0]) # Alice upvotes Bob's comment on RuboCop
CommentUpvote.create!(comment: comments[0], user: users[2]) # Charlie upvotes Bob's comment
CommentUpvote.create!(comment: comments[2], user: users[1]) # Bob upvotes Alice's helpful reply
CommentUpvote.create!(comment: comments[2], user: users[2]) # Charlie upvotes Alice's reply
CommentUpvote.create!(comment: comments[3], user: users[1]) # Bob upvotes Alice's comment on React DevTools
CommentUpvote.create!(comment: comments[5], user: users[0]) # Alice upvotes Charlie's helpful answer
CommentUpvote.create!(comment: comments[5], user: users[1]) # Bob upvotes Charlie's answer
CommentUpvote.create!(comment: comments[6], user: users[0]) # Alice upvotes Diana's comment on Vite
CommentUpvote.create!(comment: comments[6], user: users[2]) # Charlie upvotes Diana's comment
CommentUpvote.create!(comment: comments[7], user: users[0]) # Alice upvotes Prettier note
CommentUpvote.create!(comment: comments[8], user: users[2]) # Charlie upvotes Cypress feedback
CommentUpvote.create!(comment: comments[9], user: users[0]) # Alice upvotes GHA workflow tip
CommentUpvote.create!(comment: comments[10], user: users[3]) # Diana upvotes question on caching
CommentUpvote.create!(comment: comments[11], user: users[1]) # Bob upvotes caching answer
CommentUpvote.create!(comment: comments[12], user: users[0]) # Alice upvotes Grafana note
CommentUpvote.create!(comment: comments[13], user: users[2]) # Charlie upvotes Hoppscotch note
CommentUpvote.create!(comment: comments[14], user: users[0]) # Alice upvotes HTTPie note
CommentUpvote.create!(comment: comments[15], user: users[1]) # Bob upvotes Raycast note

puts "Seed data created successfully!"
puts ""
puts "Summary:"
puts "  - #{User.count} users"
puts "  - #{Tool.count} tools"
puts "  - #{Tag.count} tags (#{Tag.where(parent_id: nil).count} top-level, #{Tag.where.not(parent_id: nil).count} child tags)"
puts "  - #{List.count} lists"
puts "  - #{Comment.count} comments (#{Comment.top_level.count} top-level, #{Comment.replies.count} replies, #{Comment.solved.count} solved)"
puts "  - #{ToolTag.count} tool-tag associations"
puts "  - #{ListTool.count} list-tool associations"
puts "  - #{UserTool.count} user-tool interactions"
puts "    * #{UserTool.where(upvote: true).count} upvotes"
puts "    * #{UserTool.where(favorite: true).count} favorites"
puts "    * #{UserTool.where(subscribe: true).count} subscriptions"
puts "  - #{CommentUpvote.count} comment upvotes"
puts ""
puts "You can log in with any of these accounts:"
users.each do |user|
  puts "  - #{user.email} / password123 (username: #{user.username})"
end
