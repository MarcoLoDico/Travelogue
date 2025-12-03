class ProfilesController < ApplicationController
  allow_unauthenticated_access

  def show
    @user = User.find_by(username: params[:username])

    if @user.nil?
      redirect_to root_path, alert: "User not found"
      return
    end

    @visits = @user.visits.includes(:place).order(created_at: :desc)
    @is_own_profile = authenticated? && Current.user&.id == @user.id
  end

  # GET /u/:username/visits.json - Public API for a user's visits
  def visits
    user = User.find_by(username: params[:username])

    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end

    visits = user.visits.includes(:place).order(created_at: :desc)
    render json: {
      visits: visits.map { |v|
        {
          id: v.id,
          lat: v.lat || v.place&.lat,
          lon: v.lon || v.place&.lon,
          place_name: v.place&.name,
          country_code: v.place&.country_code,
          notes: v.notes,
          visited_on: v.visited_on
        }
      }
    }
  end
end

