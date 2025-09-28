class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :visits, dependent: :destroy
  has_many :places, through: :visits
  has_many :one_time_codes, dependent: :destroy
  has_many :oauth_applications, dependent: :destroy
  has_many :access_tokens, dependent: :destroy

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP, message: "is invalid" }
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def self.find_by_email_for_login(email)
    find_by(email_address: email.strip.downcase)
  end

  # OIDC Claims
  def oidc_claims
    {
      sub: id.to_s,
      email: email_address,
      email_verified: true,
      name: email_address.split("@").first,
      preferred_username: email_address,
      updated_at: updated_at.to_i
    }
  end

  # JWT Token Generation
  def generate_jwt_token(expires_in: Rails.application.config.jwt[:expiration])
    payload = {
      sub: id.to_s,
      email: email_address,
      iat: Time.current.to_i,
      exp: expires_in.from_now.to_i,
      iss: Rails.application.config.oidc[:issuer],
      aud: Rails.application.config.oidc[:client_id]
    }

    JWT.encode(payload, Rails.application.config.jwt[:secret], Rails.application.config.jwt[:algorithm])
  end

  def generate_refresh_token
    payload = {
      sub: id.to_s,
      type: "refresh",
      iat: Time.current.to_i,
      exp: Rails.application.config.jwt[:refresh_expiration].from_now.to_i
    }

    JWT.encode(payload, Rails.application.config.jwt[:secret], Rails.application.config.jwt[:algorithm])
  end
end
