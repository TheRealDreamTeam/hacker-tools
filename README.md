# Hacker Tools — Rails 7 / Hotwire

Rails 7.1 + Ruby 3.3 app using PostgreSQL, Redis (Action Cable), Hotwire (Turbo + Stimulus), Devise, Bootstrap, Active Storage (Cloudinary ready), RubyLLM, and Capybara/Playwright for system tests.

## Requirements
- Ruby 3.3.5 (matching `.ruby-version` / Gemfile)
- Bundler (`gem install bundler`)
- PostgreSQL 14+ running locally (16+ recommended for pgvector support)
- Redis running locally (for Action Cable; start with `redis-server`)
- Node.js (for Playwright browser install) and `npx playwright install chromium`)
- **Optional**: pgvector extension for embeddings (install with `apt-get install postgresql-16-pgvector` on Ubuntu/Debian)

## Setup
```bash
git clone <repo-url> hacker-tools
cd hacker-tools
bundle install
bin/rails db:create db:migrate
# Optional: seed data
# bin/rails db:seed

# Prepare test database
bin/rails db:test:prepare
```

## Environment variables
Create `.env` (or use your preferred secrets manager) and set:
```
OPENAI_API_KEY=...             # for RubyLLM (or provider-specific key)
```
For production, store secrets in `config/credentials.yml.enc` instead of `.env`.

## Running the app
```bash
bin/rails server
```
By default runs at http://localhost:3000. Ensure Redis is running for Action Cable.

## Testing
- All tests: `bin/rails test`
- By folder: `bin/rails test test/models`, `bin/rails test test/requests`, `bin/rails test test/system`
- System tests use Capybara + Playwright (Chromium). Install browsers once: `npx playwright install chromium`.
- Coverage via SimpleCov (output in `coverage/`).

## Active Storage (Cloudinary)
- Development uses local disk by default.
- To use Cloudinary, set `CLOUDINARY_URL` and configure `config/storage.yml`/env to select the Cloudinary service in production.

## Deployment (Heroku)

- **PostgreSQL Extensions**: pgvector is available on Heroku Postgres (Standard, Premium, Private, Shield, and Essential plans with PostgreSQL 15+)
  - Not a separate addon - it's built into Heroku Postgres
  - Migrations will automatically enable the extension if available
  - If pgvector is unavailable, the app continues to work without embeddings

## Troubleshooting
- Database connection: verify `DATABASE_URL` or local Postgres credentials.
- Redis: ensure `redis-server` is running for Action Cable and Action Job (if configured).
- Playwright: if system tests fail to launch a browser, rerun `npx playwright install chromium`.
- pgvector: If embedding generation fails, check that the extension is installed/enabled. The app works without it.
