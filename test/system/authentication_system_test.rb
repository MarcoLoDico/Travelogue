require "application_system_test_case"

class AuthenticationSystemTest < ApplicationSystemTestCase
  def setup
    clear_emails
  end

  test "complete user journey from landing page to signed in" do
    # Step 1: Visit landing page
    visit root_path

    # Should see landing page
    assert_text "Travelogue"
    assert_text "Document your travel journey"
    assert_link "Sign In"

    # Step 2: Click sign in (email flow)
    click_link "Sign In"

    # Should see sign in form
    assert_text "Sign In"
    assert_text "Enter your email to receive a login code"
    assert_field "Email address"

    # Step 3: Enter email address
    fill_in "Email address", with: "newuser@example.com"
    click_button "Send Login Code"

    # Should see code entry form
    assert_text "Enter Login Code"
    assert_text "Check your email for the 6-digit code"
    assert_field "6-Digit Code"

    # Should have sent email
    perform_enqueued_jobs
    email = last_email
    assert_not_nil email
    assert_equal "newuser@example.com", email.to.first

    # Step 4: Enter the code (use development code)
    user = User.find_by(email_address: "newuser@example.com")
    code = user.one_time_codes.last.code

    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

    # New users should see username setup page
    assert_text "Choose a Username"
    fill_in "Username", with: "newuser"
    click_button "Save & Continue"

    # After username setup, should be on home
    assert_text "My Travels"
    assert_button "Profile"

    # Should not see sign in link
    assert_no_link "Sign In"
  end

  test "existing user sign in journey" do
    user = users(:alice)

    # Step 1: Visit landing page
    visit root_path

    # Step 2: Click sign in to go to email sign-in form
    click_link "Sign In"

    # Step 3: Enter existing email
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    # Should see code entry form
    assert_text "Enter Login Code"
    assert_text "Check your email for the 6-digit code"

    # Step 4: Enter the code
    code = user.one_time_codes.last.code
    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

    # Ensure we land on home
    assert_text "My Travels"
    assert_text "Toronto"
    assert_text "Paris"
    assert_text "CA"
    assert_text "FR"
  end

  test "invalid email address handling" do
    # Step 1: Visit sign in page
    visit new_user_path

    # Step 2: Enter invalid email
    fill_in "Email address", with: "invalid-email"
    click_button "Send Login Code"

    # Should show error
    assert_text "Invalid email address."
    assert_field "Email address"

    # Email input should have red border
    email_field = find_field("Email address")
    assert email_field[:class].include?("border-red-500")
  end

  test "invalid code handling" do
    user = users(:alice)

    # Step 1: Get to code entry page
    visit new_user_path
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    # Step 2: Enter invalid code
    fill_in "6-Digit Code", with: "000000"
    click_button "Verify Code"

    # Should show error
    assert_text "Invalid or expired code. Please try again."
    assert_field "6-Digit Code"
  end

  test "resend code functionality" do
    user = users(:alice)

    # Step 1: Get to code entry page
    visit new_user_path
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    # Step 2: Click resend code
    click_link "Send another code"

    # Should show success message
    assert_text "A new code has been sent to your email address"

    # Should have sent new email
    perform_enqueued_jobs
    email = last_email
    assert_not_nil email
    assert_equal user.email_address, email.to.first
  end

  test "sign out functionality" do
    user = users(:alice)

    # Step 1: Sign in
    visit new_user_path
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    code = user.one_time_codes.last.code
    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

    # Should be signed in
    assert_text "My Travels"

    # Step 2: Sign out via sessions controller
    # Note: rack_test can't handle JavaScript modal interactions
    # We test the sign out directly via the controller
    visit session_path
    page.driver.delete session_path

    # Visit root to see if we're logged out
    visit root_path

    # Should be signed out and see landing page
    assert_text "Travelogue"
    assert_text "Document your travel journey"
    assert_link "Sign In"
    assert_no_text "My Travels"
  end

  # OAuth removed: delete OAuth-specific system tests

  test "mobile responsive design" do
    # Step 1: Visit on mobile viewport
    # Note: Rack::Test doesn't support window resizing, so we'll test the basic functionality
    visit root_path

    # Should see mobile-friendly layout
    assert_text "Travelogue"
    assert_text "Document your travel journey"

    # Step 2: Click sign in
    click_link "Sign In"

    # Should see mobile-friendly form
    assert_text "Sign In"
    assert_field "Email address"

    # Step 3: Enter email
    fill_in "Email address", with: "mobile@example.com"
    click_button "Send Login Code"

    # Should see mobile-friendly code entry
    assert_text "Enter Login Code"
    assert_field "6-Digit Code"

    # Code input should be centered and large
    code_field = find_field("6-Digit Code")
    assert code_field[:class].include?("text-center")
    assert code_field[:class].include?("text-2xl")
  end

  test "session persistence across browser refresh" do
    user = users(:alice)

    # Step 1: Sign in
    visit new_user_path
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    code = user.one_time_codes.last.code
    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

    # Should be signed in
    assert_text "My Travels"

    # Step 2: Refresh page
    page.refresh

    # Should still be signed in
    assert_text "My Travels"
    assert_no_text "Sign In"
  end

  test "multiple failed login attempts" do
    user = users(:alice)

    # Step 1: Get to code entry page
    visit new_user_path
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    # Step 2: Make multiple failed attempts
    3.times do
      fill_in "6-Digit Code", with: "000000"
      click_button "Verify Code"
      assert_text "Invalid or expired code. Please try again."
    end

    # Step 3: Successfully enter correct code
    code = user.one_time_codes.last.code
    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

    # Should still work
    assert_text "My Travels"
  end
end
