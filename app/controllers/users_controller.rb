class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome to Travelogue! Your account has been created successfully."
    else
      flash.now[:alert] = "There was a problem creating your account."
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @user = User.new(user_params)
    @user.errors.add(:email_address, "has already been taken")
    flash.now[:alert] = "An account with this email address already exists."
    render :new, status: :unprocessable_entity
  end

  private

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end
