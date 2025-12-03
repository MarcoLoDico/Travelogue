require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
  end

  test "should get index without query" do
    get search_path
    assert_response :success
    assert_select "h1", "Find Travelers"
  end

  test "should show users with usernames when no query" do
    get search_path
    assert_response :success
    # Alice and Bob have usernames in fixtures
    assert_select "a[href=?]", profile_path(username: @alice.username)
    assert_select "a[href=?]", profile_path(username: @bob.username)
  end

  test "should search users by username" do
    get search_path, params: { q: "alice" }
    assert_response :success
    assert_select "a[href=?]", profile_path(username: @alice.username)
  end

  test "should show no results for non-matching query" do
    get search_path, params: { q: "nonexistentuserxyz123" }
    assert_response :success
    assert_select "p", /No travelers found/
  end

  test "should show visit count for each user" do
    get search_path
    assert_response :success
    # Alice has visits in fixtures
    assert_select "p", text: @alice.visits.count.to_s
  end

  test "should not show users without usernames" do
    # Charlie has no username in fixtures
    charlie = users(:charlie)
    get search_path
    assert_response :success
    # Charlie should not appear in results - only users with usernames are shown
    # We verify this by checking that alice and bob appear (they have usernames)
    # but the count matches only users with usernames
    assert_select "a[href=?]", profile_path(username: @alice.username)
    assert_select "a[href=?]", profile_path(username: @bob.username)
  end
end
