class OneTimeCodeMailer < ApplicationMailer
  def send_code(user, code_or_one_time_code)
    @user = user
    if code_or_one_time_code.is_a?(String)
      @code = code_or_one_time_code
      @expires_at = 15.minutes.from_now
    else
      @code = code_or_one_time_code.code
      @expires_at = code_or_one_time_code.expires_at
    end

    mail(
      to: @user.email_address,
      subject: "Your Travelogue login code",
      from: "noreply@travelogue.dev"
    )
  end
end
