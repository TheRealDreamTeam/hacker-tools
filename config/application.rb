require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HackerTools
  class Application < Rails::Application
    config.action_controller.raise_on_missing_callback_actions = false if Rails.version >= "7.1.0"
    config.generators do |generate|
      generate.assets false
      generate.helper false
      generate.test_framework :test_unit, fixture: false
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Internationalization (i18n) configuration
    # Set default locale for the application
    config.i18n.default_locale = :en

    # Available locales - add more as needed (e.g., :es, :fr, :de)
    config.i18n.available_locales = [:en]

    # Load locale files from config/locales directory and subdirectories
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]

    # Enable locale fallbacks - if translation missing in current locale, fall back to default
    config.i18n.fallbacks = true

    # Route exceptions through the Rails router so we can render branded error pages
    # with the full application layout (navbar/footer) instead of static public files.
    config.exceptions_app = routes

    # Use SQL schema format to properly handle pgvector types
    # This allows Rails to dump vector columns correctly in db/structure.sql
    config.active_record.schema_format = :sql
  end
end
