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
    assert_select "a[href='#{session_path}'][data-turbo-method='delete']", "Sign Out"
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

    assert_select "h3", "No places visited yet"
    assert_select "p", text: /Start your travel journey by adding your first place!/
    assert_select "table", { count: 0 }
  end

  test "should show OAuth test section for unauthenticated users" do
    get root_path
    assert_response :success

    assert_select "h2", "OAuth Test"
    assert_select "p", text: /Test the OAuth 2.0 \/ OpenID Connect flow:/
    assert_select "a", text: "OAuth Authorization"
  end

  test "should not show OAuth test section for authenticated users" do
    user = users(:alice)
    sign_in_user(user)

    get root_path
    assert_response :success

    assert_select "h2", { text: "OAuth Test", count: 0 }
    assert_select "a", { text: "OAuth Authorization", count: 0 }
  end
end
