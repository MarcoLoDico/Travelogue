require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "complete sign up flow for new user" do
    # Step 1: Visit sign up page
    get new_user_path
    assert_response :success
    assert_select "h1", "Create Account"
    assert_select "input[name='user[username]']"
    assert_select "input[name='user[email_address]']"
    assert_select "input[name='user[password]']"
    assert_select "input[name='user[password_confirmation]']"

    # Step 2: Submit registration form
    assert_difference "User.count", 1 do
      post users_path, params: {
        user: {
          username: "newuser123",
          email_address: "newuser@example.com",
          password: "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end

    # Should redirect to home page
    assert_redirected_to root_path
    follow_redirect!

    # Should be signed in
    assert_response :success
    assert_select "h1", "My Travels"
    assert_select "button[data-action='click->profile-modal#open']", "Profile"

    # User should exist
    user = User.find_by(email_address: "newuser@example.com")
    assert_not_nil user
    assert user.authenticate("securepassword123")
  end

  test "sign in flow for existing user" do
    user = users(:alice)

    # Step 1: Visit sign in page
    get new_session_path
    assert_response :success
    assert_select "h1", "Sign In"
    assert_select "input[name='email_address']"
    assert_select "input[name='password']"

    # Step 2: Submit login form
    post session_path, params: {
      email_address: user.email_address,
      password: "password123"
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

  test "invalid email on registration" do
    post users_path, params: {
      user: {
        email_address: "invalid-email",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    }

    # Should render form with errors
    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end

  test "password too short on registration" do
    post users_path, params: {
      user: {
        email_address: "newuser@example.com",
        password: "short",
        password_confirmation: "short"
      }
    }

    # Should render form with errors
    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end

  test "password confirmation mismatch on registration" do
    post users_path, params: {
      user: {
        email_address: "newuser@example.com",
        password: "securepassword123",
        password_confirmation: "differentpassword"
      }
    }

    # Should render form with errors
    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end

  test "invalid credentials on login" do
    user = users(:alice)

    post session_path, params: {
      email_address: user.email_address,
      password: "wrongpassword"
    }

    # Should render form with error
    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end

  test "nonexistent user on login" do
    post session_path, params: {
      email_address: "nonexistent@example.com",
      password: "password123"
    }

    # Should render form with error
    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
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

    # Should show landing page
    assert_response :success
    assert_select "h1", "Travelogue"
    assert_select "a[href='#{new_session_path}']", "Sign In"
  end

  test "home page accessible without authentication" do
    get root_path

    # Should show home page (not redirect)
    assert_response :success
    assert_select "h1", "Travelogue"
  end

  test "session persistence across requests" do
    user = users(:alice)

    # Step 1: Sign in
    post session_path, params: {
      email_address: user.email_address,
      password: "password123"
    }
    follow_redirect!

    # Step 2: Make another request
    get root_path
    assert_response :success
    assert_select "h1", "My Travels"
  end

  test "protected routes redirect to sign in" do
    # Try to access visits without being signed in
    get visits_path

    # Should redirect to sign in
    assert_response :redirect
    assert_match %r{/session/new}, response.redirect_url
  end

  test "duplicate email on registration" do
    existing_user = users(:alice)

    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: existing_user.email_address,
          password: "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end

    # Should render form with errors
    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end

  test "navigation between sign in and sign up" do
    # Start at sign in
    get new_session_path
    assert_response :success
    assert_select "a[href='#{new_user_path}']", "Create an account"

    # Go to sign up
    get new_user_path
    assert_response :success
    assert_select "a[href='#{new_session_path}']", "Sign in"
  end
end
