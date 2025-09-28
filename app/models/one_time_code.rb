class OneTimeCode < ApplicationRecord
  belongs_to :user

  validates :code, presence: true, length: { is: 6 }
  validates :expires_at, presence: true

  scope :valid, -> { where(used: false).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def still_valid?
    !used && !expired?
  end

  def use!
    update!(used: true)
  end

  def self.generate_for(user)
    # Clean up old codes for this user
    user.one_time_codes.expired.destroy_all

    # Generate new 6-digit code
    code = rand(100000..999999).to_s
    expires_at = 15.minutes.from_now

    create!(
      user: user,
      code: code,
      expires_at: expires_at,
      used: false
    )
  end
end
