class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.find_or_initialize_by(email_address: user_params[:email_address])

    if @user.persisted?
      # User exists, send login code
      one_time_code = OneTimeCode.generate_for(@user)
      OneTimeCodeMailer.send_code(@user, one_time_code.code).deliver_now
      redirect_to new_one_time_code_path(email: @user.email_address, code: one_time_code.code),
                  notice: "We've sent a login code to your email address."
    else
      # New user, create account and send code
      @user.password = SecureRandom.hex(16) # Set a random password for passwordless flow
      if @user.save
        one_time_code = OneTimeCode.generate_for(@user)
        OneTimeCodeMailer.send_code(@user, one_time_code.code).deliver_now
        redirect_to new_one_time_code_path(email: @user.email_address, code: one_time_code.code),
                    notice: "Welcome to Travelogue! We've sent a login code to your email address."
      else
        flash.now[:alert] = "There was a problem with your email address."
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

    def user_params
      params.require(:user).permit(:email_address)
    end
end
