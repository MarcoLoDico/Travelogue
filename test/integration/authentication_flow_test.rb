require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  def setup
    clear_emails
  end

  test "complete sign up flow for new user" do
    # Step 1: Visit sign in page
    get new_user_path
    assert_response :success
    assert_select "h1", "Sign In"
    assert_select "input[name='user[email_address]']"

    # Step 2: Submit email address
    post users_path, params: {
      user: { email_address: "newuser@example.com" }
    }

    # Should redirect to code entry page with email and code parameters
    assert_response :redirect
    assert_match %r{/one_time_codes/new\?}, response.redirect_url
    assert_match %r{email=}, response.redirect_url
    assert_match %r{code=\d{6}}, response.redirect_url
    follow_redirect!

    # Should show code entry form
    assert_response :success
    assert_select "h1", "Enter Login Code"
    assert_select "input[name='code']"

    # Process enqueued emails
    perform_enqueued_jobs

    # Should have sent email
    email = last_email
    assert_not_nil email
    assert_equal "newuser@example.com", email.to.first
    assert_equal "Your Travelogue login code", email.subject

    # Should have created user
    user = User.find_by(email_address: "newuser@example.com")
    assert_not_nil user
    assert_not_nil user.one_time_codes.last

    # Step 3: Enter the code (use development code)
    code = user.one_time_codes.last.code
    post one_time_codes_path, params: {
      email: "newuser@example.com",
      code: code
    }

    # New users should be redirected to username setup
    assert_redirected_to username_path
    follow_redirect!

    # Should be on username setup page
    assert_response :success
    assert_select "h1", "Choose a Username"
  end

  test "sign in flow for existing user" do
    user = users(:alice)

    # Step 1: Visit sign in page
    get new_user_path
    assert_response :success

    # Step 2: Submit existing email address
    post users_path, params: {
      user: { email_address: user.email_address }
    }

    # Should redirect to code entry page with email and code parameters
    assert_response :redirect
    assert_match %r{/one_time_codes/new\?}, response.redirect_url
    assert_match %r{email=}, response.redirect_url
    assert_match %r{code=\d{6}}, response.redirect_url
    follow_redirect!

    # Should show code entry form
    assert_response :success
    assert_select "h1", "Enter Login Code"

    # Process enqueued emails
    perform_enqueued_jobs

    # Should have sent email
    email = last_email
    assert_not_nil email
    assert_equal user.email_address, email.to.first

    # Step 3: Enter the code
    code = user.one_time_codes.last.code
    post one_time_codes_path, params: {
      email: user.email_address,
      code: code
    }

    # Should redirect to home page
    assert_redirected_to root_path
    follow_redirect!

    # Should be signed in and see visits
    assert_response :success
    assert_select "h1", "My Travels"
    assert_select "td", "Toronto"
    assert_select "td", "Paris"
  end

  test "invalid email address" do
    # Step 1: Submit invalid email
    post users_path, params: {
      user: { email_address: "invalid-email" }
    }

    # Should render form with errors
    assert_response :unprocessable_entity
    assert_select ".bg-red-100" # Error message box
    assert_select "input[name='user[email_address]'].border-red-500" # Red border
  end

  test "invalid or expired code" do
    user = users(:alice)

    # Step 1: Get to code entry page
    post users_path, params: {
      user: { email_address: user.email_address }
    }
    follow_redirect!

    # Step 2: Enter invalid code
    post one_time_codes_path, params: {
      email: user.email_address,
      code: "000000"
    }

    # Should render form with error
    assert_response :unprocessable_entity
    assert_select ".bg-red-100" # Error message box
    assert_select "input[name='code']"
  end

  test "expired code" do
    user = users(:alice)
    expired_code = user.one_time_codes.create!(
      code: "999999",
      expires_at: 1.hour.ago,
      used: false
    )

    # Step 1: Get to code entry page
    post users_path, params: {
      user: { email_address: user.email_address }
    }
    follow_redirect!

    # Step 2: Enter expired code
    post one_time_codes_path, params: {
      email: user.email_address,
      code: "999999"
    }

    # Should render form with error
    assert_response :unprocessable_entity
    assert_select ".bg-red-100" # Error message box
  end

  test "resend code flow" do
    user = users(:alice)

    # Step 1: Get to code entry page
    post users_path, params: {
      user: { email_address: user.email_address }
    }
    follow_redirect!

    # Step 2: Resend code
    get resend_one_time_code_path(email: user.email_address)

    # Should redirect back to code entry page with email and code parameters
    assert_response :redirect
    assert_match %r{/one_time_codes/new\?}, response.redirect_url
    assert_match %r{email=}, response.redirect_url
    assert_match %r{code=\d{6}}, response.redirect_url
    follow_redirect!

    # Should show success message
    assert_response :success
    assert_select ".bg-green-100" # Success message box

    # Process enqueued emails
    perform_enqueued_jobs

    # Should have sent new email
    email = last_email
    assert_not_nil email
    assert_equal user.email_address, email.to.first
  end

  test "sign out flow" do
    user = users(:alice)
    sign_in_user(user)

    # Step 1: Visit home page (should be signed in)
    get root_path
    assert_response :success
    assert_select "h1", "My Travels"

    # Step 2: Sign out
    delete session_path

    # Should redirect to home page
    assert_redirected_to root_path
    follow_redirect!

    # Should show sign in page
    assert_response :success
    assert_select "h1", "Travelogue"
    assert_select "a[href='#{new_user_path}']", "Sign In"
  end

  test "home page accessible without authentication" do
    # Try to access home page without being signed in
    get root_path

    # Should show home page (not redirect)
    assert_response :success
    assert_select "h1", "Travelogue"
  end

  test "session persistence across requests" do
    user = users(:alice)

    # Step 1: Sign in
    post users_path, params: {
      user: { email_address: user.email_address }
    }
    follow_redirect!

    code = user.one_time_codes.last.code
    post one_time_codes_path, params: {
      email: user.email_address,
      code: code
    }
    follow_redirect!

    # Step 2: Make another request
    get root_path
    assert_response :success
    assert_select "h1", "My Travels" # Still signed in
  end

  test "multiple failed login attempts" do
    user = users(:alice)

    # Step 1: Get to code entry page
    post users_path, params: {
      user: { email_address: user.email_address }
    }
    follow_redirect!

    # Step 2: Make multiple failed attempts
    3.times do
      post one_time_codes_path, params: {
        email: user.email_address,
        code: "000000"
      }
      assert_response :unprocessable_entity
    end

    # Step 3: Successfully enter correct code
    code = user.one_time_codes.last.code
    post one_time_codes_path, params: {
      email: user.email_address,
      code: code
    }

    # Should still work
    assert_redirected_to root_path
  end
end
