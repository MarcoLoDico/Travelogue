require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index when not authenticated" do
    get root_path
    assert_response :success
    assert_select "h1", "Travelogue"
    assert_select "a[href='#{new_user_path}']", "Sign In"
    assert_select "h1", { text: "My Travels", count: 0 }
  end

  test "should get index when authenticated" do
    user = users(:alice)
    sign_in_user(user)

    get root_path
    assert_response :success
    assert_select "h1", "My Travels"
    assert_select "button[data-action='click->profile-modal#open']", "Profile"
    assert_select "#profile-modal"
    assert_select "td", "Toronto"
    assert_select "td", "Paris"
  end

  test "should show visited places for authenticated user" do
    user = users(:alice)
    sign_in_user(user)

    get root_path
    assert_response :success

    # Should show visits in table format
    assert_select "table" do
      assert_select "td", "Toronto"
      assert_select "td", "Paris"
      assert_select "td", "CA"
      assert_select "td", "FR"
    end
  end

  test "should show empty state when no visits" do
    user = users(:charlie) # User with no visits
    sign_in_user(user)

    get root_path
    assert_response :success

    # Map container should be present for adding first visit
    assert_select "[data-controller='map']"
    assert_select "table", { count: 0 }
  end

  test "should show sign in section for unauthenticated users" do
    get root_path
    assert_response :success

    assert_select "h2", "Sign In"
    assert_select "p", text: /Authenticate to access your account/
    assert_select "a[href='#{new_user_path}']", text: "Sign In"
  end
end
