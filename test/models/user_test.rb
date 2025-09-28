require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(email_address: "test@example.com", password: "password", password_confirmation: "password")
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email address" do
    @user.email_address = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email_address], "can't be blank"
  end

  test "should require unique email address" do
    duplicate_user = @user.dup
    @user.save!
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email_address], "has already been taken"
  end

  test "should normalize email address" do
    @user.email_address = "  TEST@EXAMPLE.COM  "
    @user.save!
    assert_equal "test@example.com", @user.email_address
  end

  test "should find user by email for login" do
    @user.save!
    found_user = User.find_by_email_for_login("  TEST@EXAMPLE.COM  ")
    assert_equal @user, found_user
  end

  test "should generate OIDC claims" do
    @user.save!
    claims = @user.oidc_claims

    assert_equal @user.id.to_s, claims[:sub]
    assert_equal @user.email_address, claims[:email]
    assert_equal true, claims[:email_verified]
    assert_equal "test", claims[:name]
    assert_equal @user.email_address, claims[:preferred_username]
    assert_equal @user.updated_at.to_i, claims[:updated_at]
  end

  test "should generate JWT token" do
    @user.save!
    token = @user.generate_jwt_token

    assert_not_nil token
    assert_kind_of String, token

    # Decode and verify token
    decoded = JWT.decode(token, Rails.application.config.jwt[:secret], true, { algorithm: Rails.application.config.jwt[:algorithm] })
    payload = decoded[0]

    assert_equal @user.id.to_s, payload["sub"]
    assert_equal @user.email_address, payload["email"]
    assert_equal Rails.application.config.oidc[:issuer], payload["iss"]
    assert_equal Rails.application.config.oidc[:client_id], payload["aud"]
  end

  test "should generate refresh token" do
    @user.save!
    refresh_token = @user.generate_refresh_token

    assert_not_nil refresh_token
    assert_kind_of String, refresh_token

    # Decode and verify refresh token
    decoded = JWT.decode(refresh_token, Rails.application.config.jwt[:secret], true, { algorithm: Rails.application.config.jwt[:algorithm] })
    payload = decoded[0]

    assert_equal @user.id.to_s, payload["sub"]
    assert_equal "refresh", payload["type"]
  end

  test "should have many sessions" do
    @user.save!
    session = @user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1")

    assert_includes @user.sessions, session
  end

  test "should have many visits" do
    @user.save!
    place = Place.create!(name: "Test Place", kind: 1, country_code: "US")
    visit = @user.visits.create!(place: place, visited_on: Date.current)

    assert_includes @user.visits, visit
  end

  test "should have many places through visits" do
    @user.save!
    place = Place.create!(name: "Test Place", kind: 1, country_code: "US")
    @user.visits.create!(place: place, visited_on: Date.current)

    assert_includes @user.places, place
  end

  test "should have many one time codes" do
    @user.save!
    code = @user.one_time_codes.create!(code: "123456", expires_at: 15.minutes.from_now)

    assert_includes @user.one_time_codes, code
  end

  test "should have many oauth applications" do
    @user.save!
    app = @user.oauth_applications.create!(
      name: "Test App",
      redirect_uri: "http://localhost:3001/callback"
    )

    assert_includes @user.oauth_applications, app
  end

  test "should have many access tokens" do
    @user.save!
    app = @user.oauth_applications.create!(
      name: "Test App",
      redirect_uri: "http://localhost:3001/callback"
    )
    token = @user.access_tokens.create!(
      application: app,
      token: "test_token",
      refresh_token: "test_refresh",
      expires_at: 1.hour.from_now
    )

    assert_includes @user.access_tokens, token
  end

  test "should destroy dependent records when deleted" do
    @user.save!
    place = Place.create!(name: "Test Place", kind: 1, country_code: "US")
    visit = @user.visits.create!(place: place, visited_on: Date.current)
    session = @user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1")
    code = @user.one_time_codes.create!(code: "123456", expires_at: 15.minutes.from_now)

    @user.destroy

    assert_raises(ActiveRecord::RecordNotFound) { visit.reload }
    assert_raises(ActiveRecord::RecordNotFound) { session.reload }
    assert_raises(ActiveRecord::RecordNotFound) { code.reload }
  end
end
