require "application_system_test_case"

class ProfileModalTest < ApplicationSystemTestCase
  def setup
    clear_emails
  end

  # Note: These tests use rack_test driver which doesn't support JavaScript
  # The modal is rendered but hidden by display:none initially
  # We test that the markup is present and forms work

  test "profile button and modal markup are present after login" do
    user = users(:alice)

    # Perform actual login flow
    visit new_user_path
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    code = user.one_time_codes.last.code
    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

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
    visit new_user_path
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    code = user.one_time_codes.last.code
    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

    # Visit username page directly
    visit username_path

    fill_in "Username", with: "new_alice"
    click_button "Save & Continue"

    # Should redirect to home - display name should change
    assert_text "Welcome back, new_alice!"

    # Verify database was updated
    user.reload
    assert_equal "new_alice", user.username
  end

  test "validation errors are shown for invalid username" do
    user = users(:alice)

    # Login
    visit new_user_path
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    code = user.one_time_codes.last.code
    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

    visit username_path

    fill_in "Username", with: "ab" # Too short
    click_button "Save & Continue"

    # Should show error
    assert_text "is too short"
  end

  test "user without username is redirected to setup" do
    user = users(:charlie) # User without username

    # Login
    visit new_user_path
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    code = user.one_time_codes.last.code
    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

    # Charlie should be on username setup page
    assert_current_path username_path
    assert_text "Choose a Username"

    fill_in "Username", with: "charlie_travels"
    click_button "Save & Continue"

    # Should be on home page with new display name
    assert_text "Welcome back, charlie_travels!"

    user.reload
    assert_equal "charlie_travels", user.username
  end
end
