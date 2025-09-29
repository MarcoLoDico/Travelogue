ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Authentication helpers
    def sign_in_user(user = nil)
      user ||= users(:alice)
      session = user.sessions.create!(
        user_agent: "Test Agent",
        ip_address: "127.0.0.1"
      )
      if respond_to?(:cookies)
        # For integration tests, use regular cookies
        cookies[:session_id] = session.id
      end
      user
    end

    def sign_out_user
      if respond_to?(:cookies)
        cookies.delete(:session_id)
      end
    end

    # OAuth removed: helpers deleted

    # Email helpers
    def last_email
      ActionMailer::Base.deliveries.last
    end

    def clear_emails
      ActionMailer::Base.deliveries.clear
    end

    # Database helpers
    def clean_database
      # Clean up test data in reverse dependency order
      # OAuth removed: no access tokens or applications
      OneTimeCode.destroy_all
      Session.destroy_all
      Visit.destroy_all
      Place.destroy_all
      User.destroy_all
    end
  end
end

# Integration test helpers
module ActionDispatch
  class IntegrationTest
    def follow_redirects!
      while response.redirect?
        follow_redirect!
      end
    end

    # OAuth removed: no OAuth redirects

    def assert_redirected_to_sign_in
      assert_response :redirect
      assert_match %r{/users/new}, response.redirect_url
    end

    def assert_redirected_to_home
      assert_response :redirect
      assert_equal root_url, response.redirect_url
    end
  end
end
