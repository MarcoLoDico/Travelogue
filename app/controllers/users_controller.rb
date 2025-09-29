class UsersController < ApplicationController
  allow_unauthenticated_access

  def new
    @email = params[:email]
  end

  def create
    @email = params[:user].present? ? params[:user][:email_address] : params[:email_address]
    @email = @email.strip.downcase if @email.present?

    unless @email.present? && @email.match?(URI::MailTo::EMAIL_REGEXP)
      flash.now[:alert] = "Invalid email address."
      render :new, status: :unprocessable_entity
      return
    end

    # Find or create user
    user = User.find_or_initialize_by(email_address: @email)

    unless user.persisted?
      begin
        user.save!
      rescue ActiveRecord::RecordInvalid => e
        flash.now[:alert] = "Error: #{e.message}"
        render :new, status: :unprocessable_entity
        return
      end
    end

    # Generate one-time code
    one_time_code = OneTimeCode.generate_for(user)

    # Send code via email
    OneTimeCodeMailer.send_code(user, one_time_code.code).deliver_later

    # Redirect to code entry with code in development/test
    redirect_to new_one_time_code_path(email: @email, code: (Rails.env.development? || Rails.env.test?) ? one_time_code.code : nil)
  end
end
