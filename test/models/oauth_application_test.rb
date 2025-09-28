require "test_helper"

class OauthApplicationTest < ActiveSupport::TestCase
  def setup
    @user = users(:alice)
    @app = OauthApplication.new(
      name: "Test Application",
      user: @user,
      redirect_uri: "http://localhost:3001/callback"
    )
  end

  test "should be valid with valid attributes" do
    assert @app.valid?
  end

  test "should require name" do
    @app.name = nil
    assert_not @app.valid?
    assert_includes @app.errors[:name], "can't be blank"
  end

  test "should require user" do
    @app.user = nil
    assert_not @app.valid?
    assert_includes @app.errors[:user], "must exist"
  end

  test "should require redirect_uri" do
    @app.redirect_uri = nil
    assert_not @app.valid?
    assert_includes @app.errors[:redirect_uri], "can't be blank"
  end

  test "should generate uid and secret on create" do
    @app.save!

    assert_not_nil @app.uid
    assert_not_nil @app.secret
    assert_equal 32, @app.uid.length
    assert_equal 64, @app.secret.length
  end

  test "should have unique uid" do
    @app.save!
    duplicate_app = OauthApplication.new(
      name: "Another App",
      user: @user,
      redirect_uri: "http://localhost:3002/callback"
    )
    duplicate_app.uid = @app.uid

    assert_not duplicate_app.valid?
    assert_includes duplicate_app.errors[:uid], "has already been taken"
  end

  test "should find by uid" do
    @app.save!
    found_app = OauthApplication.find_by_uid(@app.uid)
    assert_equal @app, found_app
  end

  test "should authenticate with correct credentials" do
    @app.save!
    authenticated_app = OauthApplication.authenticate(@app.uid, @app.secret)
    assert_equal @app, authenticated_app
  end

  test "should not authenticate with incorrect uid" do
    @app.save!
    authenticated_app = OauthApplication.authenticate("wrong_uid", @app.secret)
    assert_nil authenticated_app
  end

  test "should not authenticate with incorrect secret" do
    @app.save!
    authenticated_app = OauthApplication.authenticate(@app.uid, "wrong_secret")
    assert_nil authenticated_app
  end

  test "should handle scopes as array" do
    @app.scopes = [ "openid", "profile", "email" ]
    @app.save!

    assert_equal [ "openid", "profile", "email" ], @app.scopes
  end

  test "should handle scopes as string" do
    @app.scopes = "openid profile email"
    @app.save!

    assert_equal [ "openid", "profile", "email" ], @app.scopes
  end

  test "should have many access tokens" do
    @app.save!
    token = AccessToken.create!(
      application: @app,
      user: @user
    )

    assert_includes @app.access_tokens, token
  end

  test "should destroy dependent access tokens when deleted" do
    @app.save!
    token = AccessToken.create!(
      application: @app,
      user: @user
    )

    @app.destroy

    assert_raises(ActiveRecord::RecordNotFound) { token.reload }
  end
end
