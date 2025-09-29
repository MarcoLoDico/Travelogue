require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    clear_emails
    # Ensure we're in test mode for mailer
    ActionMailer::Base.delivery_method = :test
  end

  test "should get new" do
    get new_user_path
    assert_response :success
    assert_select "h1", "Sign In"
    assert_select "input[name='user[email_address]']"
  end

  test "should create new user and send code" do
    assert_difference "User.count", 1 do
      post users_path, params: {
        user: { email_address: "newuser@example.com" }
      }
    end

    assert_response :redirect
    assert_match %r{/one_time_codes/new}, response.redirect_url
    follow_redirect!

    assert_response :success
    assert_select "h1", "Enter Login Code"

    # Process enqueued emails
    perform_enqueued_jobs

    # Should have sent email
    email = last_email
    assert_not_nil email, "Expected an email to be sent, but found: #{ActionMailer::Base.deliveries.inspect}"
    assert_equal "newuser@example.com", email.to.first
    assert_equal "Your Travelogue login code", email.subject

    # Should have created one-time code
    user = User.find_by(email_address: "newuser@example.com")
    assert_not_nil user
    # Check that one_time_codes exist
    assert user.one_time_codes.any?, "Expected user to have one_time_codes, but found: #{user.one_time_codes.inspect}"
  end

  test "should send code to existing user" do
    user = users(:alice)

    assert_no_difference "User.count" do
      post users_path, params: {
        user: { email_address: user.email_address }
      }
    end

    assert_response :redirect
    assert_match %r{/one_time_codes/new}, response.redirect_url
    follow_redirect!

    assert_response :success
    assert_select "h1", "Enter Login Code"

    # Process enqueued emails
    perform_enqueued_jobs

    # Should have sent email
    email = last_email
    assert_not_nil email
    assert_equal user.email_address, email.to.first

    # Should have created one-time code
    user.reload
    assert user.one_time_codes.any?
  end

  test "should not create user with invalid email" do
    # With email format validation, invalid emails should fail validation
    post users_path, params: {
      user: { email_address: "invalid-email" }
    }

    # Should render form with errors
    assert_response :unprocessable_entity
    assert_select ".bg-red-100" # Error message box
  end

  test "should not create user with blank email" do
    assert_no_difference "User.count" do
      post users_path, params: {
        user: { email_address: "" }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".bg-red-100" # Error message box
  end

  test "should normalize email address" do
    post users_path, params: {
      user: { email_address: "  TEST@EXAMPLE.COM  " }
    }

    assert_response :redirect
    assert_match %r{/one_time_codes/new}, response.redirect_url

    user = User.find_by(email_address: "test@example.com")
    assert_not_nil user
  end

  test "should handle duplicate email gracefully" do
    user = users(:alice)

    # Try to create user with existing email
    assert_no_difference "User.count" do
      post users_path, params: {
        user: { email_address: user.email_address }
      }
    end

    # Should redirect to code entry (not error)
    assert_response :redirect
    assert_match %r{/one_time_codes/new}, response.redirect_url
    follow_redirect!

    assert_response :success
    assert_select "h1", "Enter Login Code"
  end
end
