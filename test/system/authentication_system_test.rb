require "application_system_test_case"

class AuthenticationSystemTest < ApplicationSystemTestCase
  test "complete new user journey from landing page to signed in" do
    # Step 1: Visit landing page
    visit root_path

    # Should see landing page
    assert_text "Travelogue"
    assert_text "Document your travel journey"
    assert_link "Sign In"
    assert_link "Create Account"

    # Step 2: Click create account
    click_link "Create Account"

    # Should see registration form
    assert_text "Create Account"
    assert_field "Email address"
    assert_field "Password"
    assert_field "Confirm password"

    # Step 3: Fill in registration form
    fill_in "Email address", with: "newuser@example.com"
    fill_in "Password", with: "securepassword123"
    fill_in "Confirm password", with: "securepassword123"
    click_button "Create Account"

    # Should be on home page
    assert_text "My Travels"
    assert_button "Profile"

    # Should not see sign in link
    assert_no_link "Sign In"
  end

  test "existing user sign in journey" do
    user = users(:alice)

    # Step 1: Visit landing page
    visit root_path

    # Step 2: Click sign in
    click_link "Sign In"

    # Should see sign in form
    assert_text "Sign In"
    assert_field "Email address"
    assert_field "Password"

    # Step 3: Enter credentials
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"

    # Ensure we land on home
    assert_text "My Travels"
    assert_text "Toronto"
    assert_text "Paris"
  end

  test "invalid email address on registration" do
    visit new_user_path

    fill_in "Email address", with: "invalid-email"
    fill_in "Password", with: "securepassword123"
    fill_in "Confirm password", with: "securepassword123"
    click_button "Create Account"

    # Should show error
    assert_text "is invalid"
  end

  test "short password on registration" do
    visit new_user_path

    fill_in "Email address", with: "newuser@example.com"
    fill_in "Password", with: "short"
    fill_in "Confirm password", with: "short"
    click_button "Create Account"

    # Should show error
    assert_text "is too short"
  end

  test "password mismatch on registration" do
    visit new_user_path

    fill_in "Email address", with: "newuser@example.com"
    fill_in "Password", with: "securepassword123"
    fill_in "Confirm password", with: "differentpassword"
    click_button "Create Account"

    # Should show error
    assert_text "doesn't match"
  end

  test "invalid credentials on login" do
    user = users(:alice)

    visit new_session_path

    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "wrongpassword"
    click_button "Sign In"

    # Should show error
    assert_text "Invalid email or password"
    assert_field "Email address"
    assert_field "Password"
  end

  test "sign out functionality" do
    user = users(:alice)

    # Sign in
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"

    # Should be signed in
    assert_text "My Travels"

    # Sign out via sessions controller
    page.driver.delete session_path

    # Visit root to see if we're logged out
    visit root_path

    # Should be signed out and see landing page
    assert_text "Travelogue"
    assert_link "Sign In"
    assert_no_text "My Travels"
  end

  test "mobile responsive design" do
    visit root_path

    # Should see mobile-friendly layout
    assert_text "Travelogue"
    assert_text "Document your travel journey"

    # Click sign in
    click_link "Sign In"

    # Should see sign in form
    assert_text "Sign In"
    assert_field "Email address"
    assert_field "Password"
  end

  test "session persistence across browser refresh" do
    user = users(:alice)

    # Sign in
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"

    # Should be signed in
    assert_text "My Travels"

    # Refresh page
    page.refresh

    # Should still be signed in
    assert_text "My Travels"
    assert_no_link "Sign In"
  end

  test "navigation between sign in and sign up pages" do
    # Start at sign in
    visit new_session_path
    assert_text "Sign In"
    assert_link "Create an account"

    # Go to sign up
    click_link "Create an account"
    assert_text "Create Account"
    assert_link "Sign in"

    # Go back to sign in
    click_link "Sign in"
    assert_text "Sign In"
  end
end
