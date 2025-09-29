require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
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
    assert_select "a[href='#{new_user_path}']", "Sign In with Email"
  end
end
