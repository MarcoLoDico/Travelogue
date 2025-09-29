require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test

  # Enable perform_enqueued_jobs in system tests when needed
  include ActiveJob::TestHelper
end
