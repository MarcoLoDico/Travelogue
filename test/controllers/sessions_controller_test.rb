require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_session_path
    assert_response :success
    assert_select "h1", "Sign In"
    assert_select "input[name='email_address']"
    assert_select "input[name='password']"
  end

  test "should create session with valid credentials" do
    user = users(:alice)

    post session_path, params: {
      email_address: user.email_address,
      password: "password123"
    }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "My Travels"
  end

  test "should not create session with invalid password" do
    user = users(:alice)

    post session_path, params: {
      email_address: user.email_address,
      password: "wrongpassword"
    }

    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
    assert_select "input[name='email_address']"
  end

  test "should not create session with nonexistent email" do
    post session_path, params: {
      email_address: "nonexistent@example.com",
      password: "password123"
    }

    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end

  test "should destroy session" do
    user = users(:alice)
    sign_in_user(user)

    delete session_path

    assert_redirected_to root_path
    follow_redirect!

    assert_response :success
    assert_select "div", text: "You have been signed out successfully."
    assert_select "h1", { text: "My Travels", count: 0 }
  end

  test "should redirect to sign in after logout" do
    user = users(:alice)
    sign_in_user(user)

    delete session_path
    follow_redirect!

    # Should be on landing page
    assert_select "h1", "Travelogue"
    assert_select "a[href='#{new_session_path}']", "Sign In"
  end
end
