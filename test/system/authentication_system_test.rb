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

    # Step 2: Click sign in (OAuth button)
    click_link "Sign In"

    # In system tests, avoid external OAuth redirect by going directly to email sign-in page
    visit new_user_path

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

    # In test env, consent screen is shown (no auto-approve)
    assert_text "Authorize Application"
    click_button "Authorize"

    # After consent, we return home and should be signed in
    assert_text "My Travels"
    assert_text "Places I've visited"
    assert_link "Sign Out"

    # Should not see sign in link
    assert_no_link "Sign In"
  end

  test "existing user sign in journey" do
    user = users(:alice)

    # Step 1: Visit landing page
    visit root_path

    # Step 2: Click sign in and navigate directly to email sign-in form to avoid external redirects
    click_link "Sign In"
    visit new_user_path

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

    # Consent may auto-approve depending on app; handle both cases
    if page.has_text?("Authorize Application")
      click_button "Authorize"
    end

    # Ensure we land on home
    visit root_path
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

    # Step 2: Sign out
    click_link "Sign Out"

    # Should be signed out and see landing page
    assert_text "Travelogue"
    assert_text "Document your travel journey"
    assert_link "Sign In"
    assert_no_text "My Travels"
  end

  test "OAuth authorization flow" do
    user = users(:alice)
    app = oauth_applications(:web_app)

    # Step 1: Start OAuth flow
    visit "/oauth/authorize?client_id=#{app.uid}&redirect_uri=#{app.redirect_uri}&response_type=code&scope=openid profile email&state=test123"

    # Should redirect to sign in
    assert_text "Sign In"

    # Step 2: Sign in
    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    code = user.one_time_codes.last.code
    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

    # Auto-approval for first-party apps: no consent screen shown
    # Rack::Test will not follow external redirects; after verify we should land back on root
    assert_current_path "/"
  end

  test "OAuth flow auto-approves first party (no consent)" do
    user = users(:alice)
    app = oauth_applications(:web_app)

    # Step 1: Start OAuth flow and sign in
    visit "/oauth/authorize?client_id=#{app.uid}&redirect_uri=#{app.redirect_uri}&response_type=code&scope=openid profile email&state=test123"

    fill_in "Email address", with: user.email_address
    click_button "Send Login Code"

    code = user.one_time_codes.last.code
    fill_in "6-Digit Code", with: code
    click_button "Verify Code"

    # Auto-approval means no consent choice; we should return to root
    assert_current_path "/"
  end

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
