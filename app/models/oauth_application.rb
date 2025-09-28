class OauthApplication < ApplicationRecord
  belongs_to :user
  has_many :access_tokens, foreign_key: "application_id", dependent: :destroy

  validates :name, presence: true
  validates :uid, presence: true, uniqueness: true
  validates :secret, presence: true
  validates :redirect_uri, presence: true

  before_validation :generate_credentials, on: :create

  def self.find_by_uid(uid)
    find_by(uid: uid)
  end

  def self.authenticate(uid, secret)
    find_by(uid: uid, secret: secret)
  end

  def scopes
    self[:scopes].to_s.split
  end

  def scopes=(value)
    self[:scopes] = Array(value).join(" ")
  end

  private

  def generate_credentials
    self.uid = SecureRandom.hex(16) if uid.blank?
    self.secret = SecureRandom.hex(32) if secret.blank?
  end
end
