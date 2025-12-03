require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "should show public profile for user with username" do
    get profile_path(username: @user.username)
    assert_response :success
    assert_select "h1", /#{@user.display_name}'s Travels/
  end

  test "should redirect to root with alert for non-existent username" do
    get profile_path(username: "nonexistent_user")
    assert_redirected_to root_path
    assert_equal "User not found", flash[:alert]
  end

  test "should show visits count on profile" do
    # Alice has 2 existing visits from fixtures
    get profile_path(username: @user.username)
    assert_response :success
    assert_select "p", /2 places visited/
  end

  test "should return visits JSON for public API" do
    # Alice has 2 existing visits from fixtures (Paris and Toronto)
    get profile_visits_path(username: @user.username, format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 2, json["visits"].length

    place_names = json["visits"].map { |v| v["place_name"] }
    assert_includes place_names, "Paris"
    assert_includes place_names, "Toronto"
  end

  test "should return 404 for visits API with non-existent user" do
    get profile_visits_path(username: "nonexistent_user", format: :json)
    assert_response :not_found

    json = JSON.parse(response.body)
    assert_equal "User not found", json["error"]
  end

  test "authenticated user viewing own profile should see dashboard link" do
    sign_in_as @user
    get profile_path(username: @user.username)
    assert_response :success
    assert_select "a", text: "My Dashboard"
  end

  test "authenticated user viewing other profile should see my travels link" do
    other_user = users(:bob)

    sign_in_as @user
    get profile_path(username: other_user.username)
    assert_response :success
    assert_select "a", text: "My Travels"
  end

  test "unauthenticated user should see sign in link" do
    get profile_path(username: @user.username)
    assert_response :success
    assert_select "a", text: "Sign In"
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end
end
