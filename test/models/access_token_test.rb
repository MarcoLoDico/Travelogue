require "test_helper"

class AccessTokenTest < ActiveSupport::TestCase
  def setup
    @user = users(:alice)
    @app = oauth_applications(:web_app)
    @token = AccessToken.new(
      application: @app,
      user: @user,
      scopes: "openid profile email"
    )
  end

  test "should be valid with valid attributes" do
    assert @token.valid?
  end

  test "should require application" do
    @token.application = nil
    assert_not @token.valid?
    assert_includes @token.errors[:application], "must exist"
  end

  test "should require user" do
    @token.user = nil
    assert_not @token.valid?
    assert_includes @token.errors[:user], "must exist"
  end

  test "should generate token and refresh_token on create" do
    @token.save!

    assert_not_nil @token.token
    assert_not_nil @token.refresh_token
    assert_equal 64, @token.token.length
    assert_equal 64, @token.refresh_token.length
  end

  test "should set expires_at on create" do
    @token.save!

    assert_not_nil @token.expires_at
    assert @token.expires_at > 59.minutes.from_now
    assert @token.expires_at < 61.minutes.from_now
  end

  test "should have unique token" do
    @token.save!
    duplicate_token = AccessToken.new(
      application: @app,
      user: @user,
      token: @token.token
    )

    assert_not duplicate_token.valid?
    assert_includes duplicate_token.errors[:token], "has already been taken"
  end

  test "should have unique refresh_token" do
    @token.save!
    duplicate_token = AccessToken.new(
      application: @app,
      user: @user,
      refresh_token: @token.refresh_token
    )

    assert_not duplicate_token.valid?
    assert_includes duplicate_token.errors[:refresh_token], "has already been taken"
  end

  test "should be expired when expires_at is in the past" do
    @token.expires_at = 1.hour.ago
    assert @token.expired?
  end

  test "should not be expired when expires_at is in the future" do
    @token.expires_at = 1.hour.from_now
    assert_not @token.expired?
  end

  test "should be valid when not expired" do
    @token.expires_at = 1.hour.from_now
    assert @token.still_valid?
  end

  test "should not be valid when expired" do
    @token.expires_at = 1.hour.ago
    assert_not @token.still_valid?
  end

  test "should handle scopes as array" do
    @token.scopes = [ "openid", "profile", "email" ]
    @token.save!

    assert_equal [ "openid", "profile", "email" ], @token.scopes
  end

  test "should handle scopes as string" do
    @token.scopes = "openid profile email"
    @token.save!

    assert_equal [ "openid", "profile", "email" ], @token.scopes
  end

  test "should find by token" do
    @token.save!
    found_token = AccessToken.find_by_token(@token.token)
    assert_equal @token, found_token
  end

  test "should find by refresh_token" do
    @token.save!
    found_token = AccessToken.find_by_refresh_token(@token.refresh_token)
    assert_equal @token, found_token
  end

  test "valid scope should return only valid tokens" do
    valid_token = @app.access_tokens.create!(
      user: @user,
      expires_at: 1.hour.from_now
    )

    expired_token = @app.access_tokens.create!(
      user: @user,
      expires_at: 1.hour.ago
    )

    valid_tokens = AccessToken.valid
    assert_includes valid_tokens, valid_token
    assert_not_includes valid_tokens, expired_token
  end

  test "expired scope should return only expired tokens" do
    valid_token = @app.access_tokens.create!(
      user: @user,
      expires_at: 1.hour.from_now
    )

    expired_token = @app.access_tokens.create!(
      user: @user,
      expires_at: 1.hour.ago
    )

    expired_tokens = AccessToken.expired
    assert_not_includes expired_tokens, valid_token
    assert_includes expired_tokens, expired_token
  end
end
