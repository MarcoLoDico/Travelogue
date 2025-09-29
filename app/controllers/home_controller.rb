class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    if authenticated?
      @user_places = Current.user.visits.includes(:place).order(created_at: :desc)
    end
  end
end
