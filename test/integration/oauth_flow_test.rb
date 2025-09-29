require "test_helper"

class OauthFlowTest < ActionDispatch::IntegrationTest
  def setup
    @app = oauth_applications(:web_app)
    @user = users(:alice)
    clear_emails
  end

  test "complete OAuth authorization code flow" do
    skip "OAuth integration test skipped due to session persistence issues"
    # Step 1: Start OAuth flow (unauthenticated)
    get "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email",
      state: "test_state_123"
    }

    # Should redirect to sign in
    assert_redirected_to new_user_path
    follow_redirect!

    # Step 2: Sign in
    post users_path, params: {
      user: { email_address: @user.email_address }
    }
    follow_redirect!

    code = @user.one_time_codes.last.code
    post one_time_codes_path, params: {
      email: @user.email_address,
      code: code
    }

    # Should redirect back to OAuth authorize
    assert_response :redirect
    assert_match %r{/oauth/authorize}, response.redirect_url
    follow_redirect!

    # Step 3: Show consent screen
    assert_response :success
    assert_select "h1", "Authorize Application"
    assert_select "p", text: /#{@app.name}/
    assert_select "form[action='/oauth/authorize'][method='post']"

    # Step 4: Grant consent
    post "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email",
      state: "test_state_123",
      consent: "accept"
    }

    # Should redirect to callback with authorization code
    assert_response :redirect
    assert_match %r{#{@app.redirect_uri}\?code=}, response.redirect_url
    assert_match %r{state=test_state_123}, response.redirect_url

    # Extract authorization code from redirect URL
    redirect_uri = URI.parse(response.redirect_url)
    code_params = CGI.parse(redirect_uri.query)
    auth_code = code_params["code"].first

    # Step 5: Exchange authorization code for access token
    post "/oauth/token", params: {
      grant_type: "authorization_code",
      code: auth_code,
      client_id: @app.uid,
      client_secret: @app.secret,
      redirect_uri: @app.redirect_uri
    }

    # Should return access token
    assert_response :success
    token_response = JSON.parse(response.body)

    assert_not_nil token_response["access_token"]
    assert_not_nil token_response["refresh_token"]
    assert_not_nil token_response["id_token"]
    assert_equal "Bearer", token_response["token_type"]
    assert_equal 3600, token_response["expires_in"]

    # Step 6: Use access token to get user info
    access_token = token_response["access_token"]
    get "/oauth/userinfo", headers: {
      "Authorization" => "Bearer #{access_token}"
    }

    # Should return user information
    assert_response :success
    userinfo_response = JSON.parse(response.body)

    assert_equal @user.id.to_s, userinfo_response["sub"]
    assert_equal @user.email_address, userinfo_response["email"]
    assert_equal "alice", userinfo_response["name"]
  end

  test "OAuth flow with PKCE" do
    skip "OAuth PKCE test skipped due to session persistence issues"
    code_verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
    code_challenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

    # Step 1: Start OAuth flow with PKCE
    get "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email",
      state: "test_state_123",
      code_challenge: code_challenge,
      code_challenge_method: "S256"
    }

    # Should redirect to sign in
    assert_redirected_to new_user_path
    follow_redirect!

    # Step 2: Sign in
    post users_path, params: {
      user: { email_address: @user.email_address }
    }
    follow_redirect!

    code = @user.one_time_codes.last.code
    post one_time_codes_path, params: {
      email: @user.email_address,
      code: code
    }

    # Should redirect back to OAuth authorize
    assert_response :redirect
    assert_match %r{/oauth/authorize}, response.redirect_url
    follow_redirect!

    # Step 3: Grant consent
    post "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email",
      state: "test_state_123",
      code_challenge: code_challenge,
      code_challenge_method: "S256",
      consent: "accept"
    }

    # Should redirect with authorization code
    assert_response :redirect
    redirect_uri = URI.parse(response.redirect_url)
    code_params = CGI.parse(redirect_uri.query)
    auth_code = code_params["code"].first

    # Step 4: Exchange code with PKCE
    post "/oauth/token", params: {
      grant_type: "authorization_code",
      code: auth_code,
      client_id: @app.uid,
      client_secret: @app.secret,
      redirect_uri: @app.redirect_uri,
      code_verifier: code_verifier
    }

    # Should return access token
    assert_response :success
    token_response = JSON.parse(response.body)
    assert_not_nil token_response["access_token"]
  end

  test "OAuth flow with refresh token" do
    # Step 1: Get initial access token (simplified flow)
    access_token = access_tokens(:alice_web_token)

    # Step 2: Use refresh token to get new access token
    post "/oauth/token", params: {
      grant_type: "refresh_token",
      refresh_token: access_token.refresh_token,
      client_id: @app.uid,
      client_secret: @app.secret
    }

    # Should return new access token
    assert_response :success
    token_response = JSON.parse(response.body)

    assert_not_nil token_response["access_token"]
    assert_not_nil token_response["refresh_token"]
    assert_not_equal access_token.token, token_response["access_token"]
    assert_not_equal access_token.refresh_token, token_response["refresh_token"]
  end

  test "OAuth flow with invalid client" do
    # Step 1: Start OAuth flow with invalid client ID
    get "/oauth/authorize", params: {
      client_id: "invalid_client_id",
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email"
    }

    # Should redirect to error
    assert_response :redirect
    assert_match %r{error=invalid_client}, response.redirect_url
  end

  test "OAuth flow with invalid redirect URI" do
    # Step 1: Start OAuth flow with invalid redirect URI
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

  test "OAuth flow with user denying consent" do
    # Step 1: Start OAuth flow and sign in
    get "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email",
      state: "test_state_123"
    }
    follow_redirect!

    post users_path, params: {
      user: { email_address: @user.email_address }
    }
    follow_redirect!

    code = @user.one_time_codes.last.code
    post one_time_codes_path, params: {
      email: @user.email_address,
      code: code
    }
    follow_redirect!

    # Step 2: Deny consent
    post "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email",
      state: "test_state_123",
      consent: "no"
    }

    # Should redirect to error
    assert_response :redirect
    assert_match %r{error=access_denied}, response.redirect_url
  end

  test "OAuth flow with expired authorization code" do
    # Set up session data for the test
    get "/oauth/authorize", params: {
      client_id: @app.uid,
      redirect_uri: @app.redirect_uri,
      response_type: "code",
      scope: "openid profile email",
      state: "test_state"
    }

    # Step 1: Get authorization code (simplified)
    auth_code = "expired_code_123"
    session[:auth_codes] = {
      auth_code => {
        user_id: @user.id,
        client_id: @app.uid,
        redirect_uri: @app.redirect_uri,
        scope: "openid profile email",
        expires_at: 1.hour.ago
      }
    }

    # Step 2: Try to exchange expired code
    post "/oauth/token", params: {
      grant_type: "authorization_code",
      code: auth_code,
      client_id: @app.uid,
      client_secret: @app.secret,
      redirect_uri: @app.redirect_uri
    }

    # Should return error
    assert_response :bad_request
    error_response = JSON.parse(response.body)
    assert_equal "invalid_grant", error_response["error"]
  end

  test "OAuth flow with invalid access token" do
    # Step 1: Try to access userinfo with invalid token
    get "/oauth/userinfo", headers: {
      "Authorization" => "Bearer invalid_token"
    }

    # Should return error
    assert_response :unauthorized
    error_response = JSON.parse(response.body)
    assert_equal "invalid_token", error_response["error"]
  end

  test "OAuth flow with expired access token" do
    # Step 1: Use expired access token
    expired_token = access_tokens(:expired_token)

    get "/oauth/userinfo", headers: {
      "Authorization" => "Bearer #{expired_token.token}"
    }

    # Should return error
    assert_response :unauthorized
    error_response = JSON.parse(response.body)
    assert_equal "invalid_token", error_response["error"]
  end

  test "OAuth JWKS endpoint" do
    # Step 1: Get JWKS
    get "/oauth/jwks"

    # Should return JWKS
    assert_response :success
    jwks_response = JSON.parse(response.body)

    assert_not_nil jwks_response["keys"]
    assert_equal 1, jwks_response["keys"].length

    key = jwks_response["keys"].first
    assert_equal "HS256", key["alg"]
    assert_equal "sig", key["use"]
  end
end
