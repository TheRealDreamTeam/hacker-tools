require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Use Playwright via Capybara for system tests; headless by default with opt-in headed runs.
  driven_by :playwright, screen_size: [1400, 900]
end
