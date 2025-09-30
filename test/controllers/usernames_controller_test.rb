require "test_helper"

class UsernamesControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to sign in when not authenticated" do
    get username_path
    assert_redirected_to_sign_in
  end

  test "should show username form when authenticated" do
    user = users(:alice)
    sign_in_user(user)

    get username_path
    assert_response :success
    assert_select "h1", "Choose a Username"
    # Check username field exists with the user's current username
    assert_select "input[name='user[username]']"
  end

  test "should create username for user without username" do
    user = users(:charlie) # User without username
    sign_in_user(user)

    assert_nil user.username

    post username_path, params: {
      user: { username: "charlie_travels" }
    }

    assert_redirected_to root_path
    follow_redirect!

    assert_response :success
    assert_select ".bg-green-100", text: /Username set successfully/

    user.reload
    assert_equal "charlie_travels", user.username
  end

  test "should update existing username" do
    user = users(:alice)
    sign_in_user(user)

    original_username = user.username

    patch username_path, params: {
      user: { username: "alice_new_username" }
    }

    assert_redirected_to root_path
    follow_redirect!

    assert_select ".bg-green-100", text: /Username updated successfully/

    user.reload
    assert_equal "alice_new_username", user.username
    assert_not_equal original_username, user.username
  end

  test "should strip whitespace from username" do
    user = users(:alice)
    sign_in_user(user)

    patch username_path, params: {
      user: { username: "  test_user  " }
    }

    user.reload
    assert_equal "test_user", user.username
  end

  test "should not update with invalid username" do
    user = users(:alice)
    sign_in_user(user)

    original_username = user.username

    patch username_path, params: {
      user: { username: "ab" } # Too short
    }

    assert_response :unprocessable_entity
    assert_select ".bg-red-50" # Error message container

    user.reload
    assert_equal original_username, user.username
  end

  test "should not update with username containing invalid characters" do
    user = users(:alice)
    sign_in_user(user)

    patch username_path, params: {
      user: { username: "invalid username!" } # Spaces and special chars
    }

    assert_response :unprocessable_entity
    user.reload
    assert_not_equal "invalid username!", user.username
  end

  test "should not update with duplicate username" do
    user = users(:alice)
    other_user = users(:bob)
    sign_in_user(user)

    original_username = user.username
    assert_not_nil other_user.username, "Bob should have a username in fixtures"

    # Try to use Bob's username
    patch username_path, params: {
      user: { username: other_user.username }
    }

    # Username uniqueness validation should prevent this
    # Note: The test may pass if case-insensitive uniqueness allows it temporarily
    # but the database constraint should prevent the actual save
    assert_response :unprocessable_entity
    assert_select ".bg-red-50" # Error message container

    user.reload
    assert_equal original_username, user.username
  end
end
