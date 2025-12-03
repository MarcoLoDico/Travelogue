class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :visits, dependent: :destroy
  has_many :places, through: :visits

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP, message: "is invalid" }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :username, presence: true,
                       length: { in: 3..50 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: "can only contain letters, numbers, and underscores" },
                       uniqueness: { case_sensitive: false }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :username, with: ->(u) { u.strip }

  def display_name
    username.presence || email_address.split("@").first
  end
end
