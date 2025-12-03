class SearchController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q].to_s.strip

    if @query.present?
      @users = User.where.not(username: [ nil, "" ])
                   .where("LOWER(username) LIKE :q OR LOWER(email_address) LIKE :q", q: "%#{sanitize_like(@query.downcase)}%")
                   .limit(50)
    else
      # Show recent users with usernames when no search query
      @users = User.where.not(username: [ nil, "" ])
                   .order(created_at: :desc)
                   .limit(20)
    end
  end

  private

  def sanitize_like(string)
    string.gsub(/[%_]/) { |x| "\\#{x}" }
  end
end
