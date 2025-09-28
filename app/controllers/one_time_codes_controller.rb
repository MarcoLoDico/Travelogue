class OneTimeCodesController < ApplicationController
  allow_unauthenticated_access

  def new
    @email = params[:email]
    @dev_code = params[:code] if Rails.env.development?
    @one_time_code = OneTimeCode.new
  end

  def create
    @email = params[:email]
    @code = params[:code]

    user = User.find_by_email_for_login(@email)

    if user.nil?
      flash.now[:alert] = "Invalid email address."
      render :new, status: :unprocessable_entity
      return
    end

    # Find the code by exact match first, then check validity
    one_time_code = user.one_time_codes.find_by(code: @code)

    # Check if code is valid (not used and not expired)
    if one_time_code && !one_time_code.used && one_time_code.expires_at > Time.current
      # Code is valid, proceed
    else
      one_time_code = nil
    end

    if one_time_code
      one_time_code.use!
      start_new_session_for user

      # Check if this is an OAuth flow
      if session[:oauth_params]
        oauth_params = session[:oauth_params]
        session.delete(:oauth_params)
        redirect_to "/oauth/authorize?#{oauth_params.to_query}"
      else
        redirect_to root_path, notice: "Welcome back! You've been signed in successfully."
      end
    else
      flash.now[:alert] = "Invalid or expired code. Please try again."
      render :new, status: :unprocessable_entity
    end
  end

  def resend
    @email = params[:email]
    user = User.find_by_email_for_login(@email)

    if user
      one_time_code = OneTimeCode.generate_for(user)
      OneTimeCodeMailer.send_code(user, one_time_code.code).deliver_later
      redirect_to new_one_time_code_path(email: @email, code: one_time_code.code),
                  notice: "A new code has been sent to your email address."
    else
      redirect_to new_user_path, alert: "Invalid email address."
    end
  end
end
