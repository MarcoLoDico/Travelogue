class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    if authenticated?
      @user_places = Current.user.visits.includes(:place).order(created_at: :desc)
    end
  end

  # Initiate OAuth authorization with PKCE
  def start_oauth
    application = OauthApplication.find_by!(name: "Travelogue Web App")

    state = SecureRandom.hex(16)
    nonce = SecureRandom.hex(16)
    code_verifier = SecureRandom.urlsafe_base64(64)
    code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).delete("=")

    session[:pkce] = { code_verifier: code_verifier, created_at: Time.current.to_i }

    authorize_params = {
      client_id: application.uid,
      redirect_uri: application.redirect_uri,
      response_type: "code",
      scope: "openid profile email",
      state: state,
      nonce: nonce,
      code_challenge: code_challenge,
      code_challenge_method: "S256"
    }

    redirect_to oauth_authorize_path(authorize_params)
  end
end
