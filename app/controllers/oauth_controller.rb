require "net/http"
require "uri"
require "json"

class OauthController < ApplicationController
  allow_unauthenticated_access only: [ :authorize, :token, :userinfo, :jwks, :callback ]

  # OAuth token endpoint should skip CSRF protection
  skip_before_action :verify_authenticity_token, only: :token

  # OAuth 2.0 Authorization Endpoint
  def authorize
    @client_id = params[:client_id]
    @redirect_uri = params[:redirect_uri]
    @response_type = params[:response_type]
    @scope = params[:scope]
    @state = params[:state]
    @nonce = params[:nonce]
    @code_challenge = params[:code_challenge]
    @code_challenge_method = params[:code_challenge_method]

    # Validate client
    @application = OauthApplication.find_by_uid(@client_id)
    unless @application
      redirect_to_error(@redirect_uri, "invalid_client", "Invalid client ID")
      return
    end

    # Validate redirect URI
    unless @application.redirect_uri.include?(@redirect_uri)
      redirect_to_error(@redirect_uri, "invalid_request", "Invalid redirect URI")
      return
    end

    # Check if user is authenticated
    unless authenticated?
    # Store OAuth parameters in session for after authentication
    session[:oauth_params] = {
      client_id: @client_id,
      redirect_uri: @redirect_uri,
      response_type: @response_type,
      scope: @scope,
      state: @state,
      nonce: @nonce,
      code_challenge: @code_challenge,
      code_challenge_method: @code_challenge_method,
      created_at: Time.current.to_i  # Security: timestamp for validation
    }
      redirect_to new_user_path
      return
    end

    # User is authenticated - auto-approve for first-party apps
    # For third-party apps, you'd show consent screen here
    if first_party_app?(@application, Current.user)
      # Auto-approve: generate authorization code directly
      code = generate_authorization_code(Current.user, session[:oauth_params] || params.to_unsafe_h.slice(*%w[client_id redirect_uri response_type scope state nonce code_challenge code_challenge_method]))

      redirect_uri = URI.parse(@redirect_uri)
      redirect_uri.query = {
        code: code,
        state: @state
      }.compact.to_query

      redirect_to redirect_uri.to_s, allow_other_host: true
    else
      # Show consent screen for third-party apps
      render :authorize
    end
  end

  # OAuth callback endpoint
  def callback
    code = params[:code]
    state = params[:state]

    oauth_params = session[:oauth_params] || {}
    pkce = session[:pkce] || {}

    application = OauthApplication.find_by_uid(oauth_params[:client_id])
    unless application
      redirect_to root_path, alert: "OAuth client not found"
      return
    end

    token_uri = URI.parse("#{request.base_url}/oauth/token")
    request_body = {
      grant_type: "authorization_code",
      code: code,
      client_id: application.uid,
      client_secret: application.secret,
      redirect_uri: oauth_params[:redirect_uri] || oauth_callback_url,
      code_verifier: pkce[:code_verifier]
    }

    http = Net::HTTP.new(token_uri.host, token_uri.port)
    http.use_ssl = token_uri.scheme == "https"
    req = Net::HTTP::Post.new(token_uri.request_uri)
    req["Content-Type"] = "application/x-www-form-urlencoded"
    req.body = URI.encode_www_form(request_body.compact)

    res = http.request(req)

    if res.code.to_i.between?(200, 299)
      body = JSON.parse(res.body) rescue {}
      session[:oauth_tokens] = {
        access_token: body["access_token"],
        refresh_token: body["refresh_token"],
        id_token: body["id_token"],
        expires_at: Time.current.to_i + body.fetch("expires_in", 3600).to_i
      }
      session.delete(:oauth_params)
      session.delete(:pkce)

      redirect_to root_path, notice: "You are signed in."
    else
      Rails.logger.warn("OAuth token exchange failed: #{res.code} #{res.body}")
      redirect_to root_path, alert: "OAuth token exchange failed."
    end
  end

  # Handle authorization consent
  def consent
    oauth_params = session[:oauth_params] || {}

    # Get redirect_uri from params if not in session
    redirect_uri_str = oauth_params[:redirect_uri] || params[:redirect_uri]

    if redirect_uri_str.blank?
      redirect_to root_path, alert: "Invalid OAuth request"
      return
    end

    if params[:consent] == "accept"
      # Generate authorization code
      code = generate_authorization_code(Current.user, oauth_params)

      # Build redirect URI with code
      redirect_uri = URI.parse(redirect_uri_str)
      redirect_uri.query = {
        code: code,
        state: oauth_params[:state] || params[:state]
      }.compact.to_query

      redirect_to redirect_uri.to_s, allow_other_host: true
    else
      # User denied consent
      redirect_uri = URI.parse(redirect_uri_str)
      redirect_uri.query = {
        error: "access_denied",
        state: oauth_params[:state] || params[:state]
      }.compact.to_query

      redirect_to redirect_uri.to_s, allow_other_host: true
    end

    session.delete(:oauth_params)
  end

  # OAuth 2.0 Token Endpoint
  def token
    grant_type = params[:grant_type]

    case grant_type
    when "authorization_code"
      handle_authorization_code_grant
    when "refresh_token"
      handle_refresh_token_grant
    else
      render json: { error: "unsupported_grant_type" }, status: :bad_request
    end
  end

  # OpenID Connect UserInfo Endpoint
  def userinfo
    token = extract_bearer_token

    unless token
      render json: { error: "invalid_token" }, status: :unauthorized
      return
    end

    access_token = AccessToken.find_by_token(token)

    unless access_token&.still_valid?
      render json: { error: "invalid_token" }, status: :unauthorized
      return
    end

    # Return user claims
    render json: access_token.user.oidc_claims
  end

  # JWKS Endpoint for JWT verification
  def jwks
    # For HMAC, we return a key identifier
    # In production, you'd want to use RSA keys
    render json: {
      keys: [ {
        kty: "oct",
        kid: "travelogue-key-1",
        use: "sig",
        alg: "HS256"
      } ]
    }
  end

  private

  def first_party_app?(application, user)
    # Auto-approve if:
    # 1. App belongs to the same user
    # 2. Or it's a trusted first-party app
    application.user == user || trusted_first_party_app?(application)
  end

  def trusted_first_party_app?(application)
    # Auto-approve first-party applications (same domain/service)
    # In production, this should be configurable via application settings
    Rails.env.development? && application.name&.include?("Travelogue")
  end

  def generate_authorization_code(user, oauth_params)
    code = SecureRandom.hex(32)

    # Store code in session (in production, use Redis or database)
    session[:auth_codes] ||= {}
    session[:auth_codes][code] = {
      user_id: user.id,
      client_id: oauth_params[:client_id],
      redirect_uri: oauth_params[:redirect_uri],
      scope: oauth_params[:scope],
      nonce: oauth_params[:nonce],
      code_challenge: oauth_params[:code_challenge],
      code_challenge_method: oauth_params[:code_challenge_method],
      expires_at: 10.minutes.from_now
    }

    code
  end

  def handle_authorization_code_grant
    code = params[:code]
    client_id = params[:client_id]
    client_secret = params[:client_secret]
    redirect_uri = params[:redirect_uri]
    code_verifier = params[:code_verifier]

    # Validate client
    application = OauthApplication.authenticate(client_id, client_secret)
    unless application
      render json: { error: "invalid_client" }, status: :unauthorized
      return
    end

    # Validate authorization code
    auth_code_data = session[:auth_codes]&.[](code)
    unless auth_code_data
      render json: { error: "invalid_grant" }, status: :bad_request
      return
    end

    unless auth_code_data[:expires_at] && auth_code_data[:expires_at] > Time.current
      render json: { error: "invalid_grant" }, status: :bad_request
      return
    end

    # Validate redirect URI
    unless auth_code_data[:redirect_uri] == redirect_uri
      render json: { error: "invalid_grant" }, status: :bad_request
      return
    end

    # Validate PKCE
    if auth_code_data[:code_challenge]
      expected_challenge = case auth_code_data[:code_challenge_method]
      when "S256"
        Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier.to_s)).delete("=")
      else
        code_verifier.to_s
      end

      unless auth_code_data[:code_challenge] == expected_challenge
        render json: { error: "invalid_grant" }, status: :bad_request
        return
      end
    end

    # Get user
    user = User.find(auth_code_data[:user_id])

    # Create access token
    access_token = user.access_tokens.create!(
      application: application,
      scopes: auth_code_data[:scope] || "openid profile email"
    )

    # Generate ID token
    id_token = generate_id_token(user, application, auth_code_data[:nonce])

    # Clean up authorization code
    session[:auth_codes].delete(code)

    # Return tokens
    render json: {
      access_token: access_token.token,
      token_type: "Bearer",
      expires_in: 3600,
      refresh_token: access_token.refresh_token,
      scope: access_token.scopes.join(" "),
      id_token: id_token
    }
  end

  def handle_refresh_token_grant
    refresh_token = params[:refresh_token]
    client_id = params[:client_id]
    client_secret = params[:client_secret]

    # Validate client
    application = OauthApplication.authenticate(client_id, client_secret)
    unless application
      render json: { error: "invalid_client" }, status: :unauthorized
      return
    end

    # Find access token
    access_token = AccessToken.find_by_refresh_token(refresh_token)
    unless access_token&.application == application
      render json: { error: "invalid_grant" }, status: :bad_request
      return
    end

    # Create new access token
    new_access_token = access_token.user.access_tokens.create!(
      application: application,
      scopes: access_token.scopes
    )

    # Revoke old token
    access_token.destroy

    render json: {
      access_token: new_access_token.token,
      token_type: "Bearer",
      expires_in: 3600,
      refresh_token: new_access_token.refresh_token,
      scope: new_access_token.scopes.join(" ")
    }
  end

  def generate_id_token(user, application, nonce)
    payload = {
      iss: Rails.application.config.oidc[:issuer],
      sub: user.id.to_s,
      aud: application.uid,
      exp: 1.hour.from_now.to_i,
      iat: Time.current.to_i,
      nonce: nonce
    }.merge(user.oidc_claims)

    JWT.encode(payload, Rails.application.config.jwt[:secret], Rails.application.config.jwt[:algorithm])
  end

  def extract_bearer_token
    auth_header = request.headers["Authorization"]
    return nil unless auth_header&.start_with?("Bearer ")

    auth_header.split(" ", 2).last
  end

  def redirect_to_error(redirect_uri, error, description)
    uri = URI.parse(redirect_uri)
    uri.query = { error: error, error_description: description }.to_query
    redirect_to uri.to_s, allow_other_host: true
  end
end
