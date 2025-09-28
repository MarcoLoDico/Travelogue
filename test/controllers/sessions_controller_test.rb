require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_session_path
    assert_response :success
  end

  test "should create session with valid credentials" do
    user = users(:alice)
    user.update!(password: "password", password_confirmation: "password")

    post session_path, params: {
      email_address: user.email_address,
      password: "password"
    }

    assert_redirected_to root_path
    follow_redirect!

    assert_response :success
    assert_select "h1", "My Travels"
  end

  test "should not create session with invalid credentials" do
    user = users(:alice)
    user.update!(password: "password", password_confirmation: "password")

    post session_path, params: {
      email_address: user.email_address,
      password: "wrong_password"
    }

    assert_redirected_to new_session_path
    follow_redirect!

    assert_response :success
    assert_select "div", text: "Try another email address or password."
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
    assert_select "p", text: /Document your travel journey/
    assert_select "a[href='#{new_user_path}']", "Sign In"
  end
end
