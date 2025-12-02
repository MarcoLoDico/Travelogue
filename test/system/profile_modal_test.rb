require "application_system_test_case"

class ProfileModalTest < ApplicationSystemTestCase
  # Note: These tests use rack_test driver which doesn't support JavaScript
  # The modal is rendered but hidden by display:none initially
  # We test that the markup is present and forms work

  test "profile button and modal markup are present after login" do
    user = users(:alice)

    # Perform actual login flow
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"

    # Should be on home page
    assert_text "My Travels"

    # Should see profile button
    assert_button "Profile"

    # Modal markup should be in the DOM (even if hidden by display:none)
    assert_selector "#profile-modal", visible: :all
  end

  # Test updating username via username controller directly
  # since we can't interact with the modal with rack_test driver
  test "username can be updated" do
    user = users(:alice)

    # Login
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"

    # Visit username page directly
    visit username_path

    fill_in "Username", with: "new_alice"
    click_button "Save & Continue"

    # Should redirect to home
    assert_text "My Travels"

    # Verify database was updated
    user.reload
    assert_equal "new_alice", user.username
  end

  test "validation errors are shown for invalid username" do
    user = users(:alice)

    # Login
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"

    visit username_path

    fill_in "Username", with: "ab" # Too short
    click_button "Save & Continue"

    # Should show error
    assert_text "is too short"
  end
end
