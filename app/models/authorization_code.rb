class AuthorizationCode < ApplicationRecord
  belongs_to :user
  belongs_to :application, class_name: "OauthApplication"

  validates :code, presence: true, uniqueness: true
  validates :redirect_uri, presence: true
  validates :expires_at, presence: true

  scope :valid, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end
end
