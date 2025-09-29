class AccessToken < ApplicationRecord
  belongs_to :application, class_name: "OauthApplication"
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :refresh_token, presence: true, uniqueness: true

  before_validation :generate_tokens, on: :create

  scope :valid, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def still_valid?
    !expired?
  end

  def scopes
    self[:scopes].to_s.split
  end

  def scopes=(value)
    self[:scopes] = Array(value).join(" ")
  end

  def self.find_by_token(token)
    find_by(token: token)
  end

  def self.find_by_refresh_token(refresh_token)
    find_by(refresh_token: refresh_token)
  end

  private

  def generate_tokens
    self.token = SecureRandom.hex(32) if token.blank?
    self.refresh_token = SecureRandom.hex(32) if refresh_token.blank?
    self.expires_at = 1.hour.from_now if expires_at.blank?
  end
end
