class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :visits, dependent: :destroy
  has_many :places, through: :visits
  has_many :one_time_codes, dependent: :destroy
  # OAuth removed: oauth_applications, access_tokens

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP, message: "is invalid" }
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def self.find_by_email_for_login(email)
    find_by(email_address: email.strip.downcase)
  end

  # Password authentication removed; email-based OTP only

  # OAuth/OIDC/JWT removed: email-only authentication via one-time codes
end
