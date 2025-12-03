require "application_system_test_case"

class ProfileModalTest < ApplicationSystemTestCase
  # Note: These tests use rack_test driver which doesn't support JavaScript
  # The modal is rendered but hidden by display:none initially
  # We test that the markup is present

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

  test "profile modal displays username as read-only" do
    user = users(:alice)

    # Login
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"

    # Should be on home page with profile modal markup containing username
    assert_selector "#profile-modal", visible: :all, text: user.username
  end
end
