ENV["RAILS_ENV"] ||= "test"

# Start coverage before Rails boots so we measure the full test run.
require "simplecov"
SimpleCov.start "rails"

require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "vcr"
require "capybara/playwright"
require "factory_bot_rails"
require "active_support/testing/time_helpers"

# Block external HTTP calls; allow local/test servers and metadata hosts.
WebMock.disable_net_connect!(allow_localhost: true, allow: [/^127\.0\.0\.1/, /^0\.0\.0\.0/, /localhost/])

# Record/stub HTTP interactions deterministically for test runs.
VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {record: :once, match_requests_on: %i[method uri body]}
  config.allow_http_connections_when_no_cassette = false
end

# Configure Capybara to use Playwright as the primary system-test driver.
Capybara.default_max_wait_time = 5
Capybara.register_driver :playwright do |app|
  headless = ENV.fetch("HEADFUL_SYSTEM_TESTS", "false") != "true"
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    headless: headless,
    viewport_size: {width: 1400, height: 900}
  )
end
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :playwright

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    include ActiveJob::TestHelper
    include FactoryBot::Syntax::Methods
    include ActiveSupport::Testing::TimeHelpers
    include Devise::Test::IntegrationHelpers
  end
end
