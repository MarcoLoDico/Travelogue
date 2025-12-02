class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :visits, dependent: :destroy
  has_many :places, through: :visits

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP, message: "is invalid" }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
