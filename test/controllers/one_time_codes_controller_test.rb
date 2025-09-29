require "test_helper"

class OneTimeCodesControllerTest < ActionDispatch::IntegrationTest
  def setup
    clear_emails
  end

  test "should get new" do
    get new_one_time_code_path(email: "test@example.com")
    assert_response :success
    assert_select "h1", "Enter Login Code"
    assert_select "input[name='code']"
    assert_select "input[name='email'][value='test@example.com']"
  end

  test "should get new with development code" do
    get new_one_time_code_path(email: "test@example.com", code: "123456")
    assert_response :success
    assert_select "h1", "Enter Login Code"

    if Rails.env.development?
      assert_text "Development Mode:"
      assert_text "Your code is: 123456"
    end
  end

  test "should create session with valid code" do
    user = users(:alice)
    code = user.one_time_codes.create!(
      code: "111111",
      expires_at: 15.minutes.from_now,
      used: false
    )

    post one_time_codes_path, params: {
      email: user.email_address,
      code: "111111"
    }

    assert_redirected_to root_path
    follow_redirect!

    assert_response :success
    assert_select "h1", "My Travels"

    # Code should be marked as used
    code.reload
    assert code.used, "Expected code to be marked as used, but it wasn't. Code state: #{code.attributes}"
  end

  test "should not create session with invalid code" do
    user = users(:alice)

    post one_time_codes_path, params: {
      email: user.email_address,
      code: "000000"
    }

    assert_response :unprocessable_entity
    assert_select ".bg-red-100" # Error message box
    assert_select "input[name='code']"
  end

  test "should not create session with expired code" do
    user = users(:alice)
    expired_code = user.one_time_codes.create!(
      code: "999999",
      expires_at: 1.hour.ago,
      used: false
    )

    assert expired_code.expired?, "Code should be expired: expires_at=#{expired_code.expires_at}, current=#{Time.current}"

    post one_time_codes_path, params: {
      email: user.email_address,
      code: "999999"
    }

    assert_response :unprocessable_entity
    assert_select ".bg-red-100" # Error message box
  end

  test "should not create session with used code" do
    user = users(:alice)
    used_code = user.one_time_codes.create!(
      code: "888888",
      expires_at: 15.minutes.from_now,
      used: true
    )

    post one_time_codes_path, params: {
      email: user.email_address,
      code: "888888"
    }

    assert_response :unprocessable_entity
    assert_select ".bg-red-100" # Error message box
  end

  test "should not create session with invalid email" do
    post one_time_codes_path, params: {
      email: "nonexistent@example.com",
      code: "123456"
    }

    assert_response :unprocessable_entity
    assert_select ".bg-red-100" # Error message box
  end

  test "should resend code" do
    user = users(:alice)

    get resend_one_time_code_path(email: user.email_address)

    # Should redirect to new_one_time_code_path with email and code parameters
    assert_response :redirect
    assert_match %r{/one_time_codes/new\?code=\d{6}&email=#{CGI.escape(user.email_address)}}, response.redirect_url

    follow_redirect!

    assert_response :success
    assert_select ".bg-green-100" # Success message box

    # Should have queued new email (deliver_later queues the email)
    # In test environment, we need to process the queue to get the email
    perform_enqueued_jobs
    email = last_email
    assert_not_nil email
    assert_equal user.email_address, email.to.first
  end

  test "should not resend code for invalid email" do
    get resend_one_time_code_path(email: "nonexistent@example.com")

    assert_redirected_to new_user_path
    follow_redirect!

    assert_response :success
    assert_select ".bg-red-100" # Error message box
  end
end
