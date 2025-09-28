class OneTimeCodeMailer < ApplicationMailer
  def send_code(user, code)
    @user = user
    @code = code
    @expires_at = 15.minutes.from_now

    mail to: @user.email_address, subject: "Your Travelogue login code"
  end
end
