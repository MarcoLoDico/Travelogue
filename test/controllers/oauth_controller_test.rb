require "test_helper"

class OauthControllerTest < ActionDispatch::IntegrationTest
  def setup
    @app = oauth_applications(:web_app)
    @user = users(:alice)
  end

  test "should get authorize with valid client" do
    get "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email"
    }

    # Should redirect to sign in since not authenticated
    assert_redirected_to new_user_path
  end

  test "should get authorize with invalid client" do
    get "/oauth/authorize", params: {
      client_id: "invalid_client",
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email"
    }

    # Should redirect to error
    assert_response :redirect
    assert_match %r{error=invalid_client}, response.redirect_url
  end

  test "should get authorize with invalid redirect URI" do
    get "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: "http://evil.com/callback",
      response_type: "code",
      scope: "openid profile email"
    }

    # Should redirect to error
    assert_response :redirect
    assert_match %r{error=invalid_request}, response.redirect_url
  end

  test "should auto-approve first-party and redirect when authenticated" do
    sign_in_user(@user)

    get "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email",
      state: "test_state"
    }

    assert_response :redirect
    assert_match %r{#{@app.redirect_uri}\?code=}, response.redirect_url
  end

  test "should redirect with code when authenticated (no consent)" do
    sign_in_user(@user)
    get "/oauth/authorize", params: { client_id: @app.uid, redirect_uri: @app.redirect_uri, response_type: "code", scope: "openid profile email", state: "test_state" }
    assert_response :redirect
    assert_match %r{#{@app.redirect_uri}\?code=}, response.redirect_url
  end

  # Consent denial not supported in first-party mode


  test "should not exchange invalid authorization code" do
    post "/oauth/token", params: {
      grant_type: "authorization_code",
      code: "invalid_code",
      client_id: @app.uid,
      client_secret: @app.secret,
      redirect_uri: @app.redirect_uri
    }

    assert_response :bad_request
    error_response = JSON.parse(response.body)
    assert_equal "invalid_grant", error_response["error"]
  end

  test "should not exchange expired authorization code" do
    sign_in_user(@user)

    auth_code = "expired_code_123"
    # Set up session data for the test
    get "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email",
      state: "test_state"
    }

    # Manually set expired auth code in session
    session[:auth_codes] = {
      auth_code => {
        user_id: @user.id,
        client_id: @app.uid,
        redirect_uri: @app.redirect_uri,
        scope: "openid profile email",
        expires_at: 1.hour.ago
      }
    }

    post "/oauth/token", params: {
      grant_type: "authorization_code",
      code: auth_code,
      client_id: @app.uid,
      client_secret: @app.secret,
      redirect_uri: @app.redirect_uri
    }

    assert_response :bad_request
    error_response = JSON.parse(response.body)
    assert_equal "invalid_grant", error_response["error"]
  end

  test "should refresh access token" do
    access_token = access_tokens(:alice_web_token)

    post "/oauth/token", params: {
      grant_type: "refresh_token",
      refresh_token: access_token.refresh_token,
      client_id: @app.uid,
      client_secret: @app.secret
    }

    assert_response :success
    token_response = JSON.parse(response.body)

    assert_not_nil token_response["access_token"]
    assert_not_nil token_response["refresh_token"]
    assert_not_equal access_token.token, token_response["access_token"]
  end

  test "should get userinfo with valid token" do
    access_token = access_tokens(:alice_web_token)

    get "/oauth/userinfo", headers: {
      "Authorization" => "Bearer #{access_token.token}"
    }

    assert_response :success
    userinfo_response = JSON.parse(response.body)

    assert_equal @user.id.to_s, userinfo_response["sub"]
    assert_equal @user.email_address, userinfo_response["email"]
    assert_equal "alice", userinfo_response["name"]
  end

  test "should not get userinfo with invalid token" do
    get "/oauth/userinfo", headers: {
      "Authorization" => "Bearer invalid_token"
    }

    assert_response :unauthorized
    error_response = JSON.parse(response.body)
    assert_equal "invalid_token", error_response["error"]
  end

  test "should not get userinfo with expired token" do
    expired_token = access_tokens(:expired_token)

    get "/oauth/userinfo", headers: {
      "Authorization" => "Bearer #{expired_token.token}"
    }

    assert_response :unauthorized
    error_response = JSON.parse(response.body)
    assert_equal "invalid_token", error_response["error"]
  end

  test "should get jwks" do
    get "/oauth/jwks"

    assert_response :success
    jwks_response = JSON.parse(response.body)

    assert_not_nil jwks_response["keys"]
    assert_equal 1, jwks_response["keys"].length

    key = jwks_response["keys"].first
    assert_equal "HS256", key["alg"]
    assert_equal "sig", key["use"]
  end

  test "should get callback and redirect to root after exchange" do
    # Minimal params; we expect redirect to root since server exchanges
    get "/oauth/callback", params: { code: "test_code_123", state: "test_state" }
    assert_response :redirect
    assert_redirected_to root_path
  end
end
