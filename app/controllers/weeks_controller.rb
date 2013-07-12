class WeeksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /weeks
  # GET /weeks.json
  def index
    @current_year = Date.today.year
    @weeks = Week.where(year: @current_year)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @weeks }
    end
  end

  # POST /weeks
  def update
    # TODO check admin user
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end

    # TODO update start times
    redirect_to "/weeks"
  end
end
