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
