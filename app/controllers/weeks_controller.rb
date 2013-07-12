class WeeksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /weeks
  # GET /weeks.json
  def index
    @current_year = Date.today.year
    @weeks = Week.where(year: @current_year).order(:number)

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
    updated_weeks = false
    confirmation_message = ""
    if !params["save"].nil?
      Week.transaction do
        begin
          Week.where(year: Date.today.year).order(:number).each { |week|
            week_start_time_string = params["weekstart" + week.number.to_s]
            week_start_time = DateTime.strptime(week_start_time_string + " Atlantic Time (Canada)",
                                                "%m/%d/%Y %I:%M %p %Z")
            if week.start_time != week_start_time
              week.update_attribute(:start_time, week_start_time)
              updated_weeks = true
            end
          }
          if updated_weeks
            confirmation_message = "Successfully updated start times"
          end
        rescue Exception => e
          confirmation_message = "Error: Invalid date formatting. Please try again."
        end
      end
    end
    redirect_to "/weeks", notice: confirmation_message
  end
end
