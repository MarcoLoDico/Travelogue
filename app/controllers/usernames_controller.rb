class UsernamesController < ApplicationController
  before_action :require_authentication

  def show
    @user = Current.user
  end

  def create
    @user = Current.user

    if @user.update(user_params)
      redirect_to root_path, notice: "Username set successfully! Welcome to Travelogue."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update
    @user = Current.user

    if @user.update(user_params)
      redirect_to root_path, notice: "Username updated successfully!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:username)
  end
end
