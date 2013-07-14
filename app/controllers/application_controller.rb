class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  helper_method :current_user
  helper_method :current_week

  private

  # returns the current logged-in user
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  # returns the current week of all weeks for the given year
  def current_week
    return get_current_week_from_weeks(Week.where(year: Date.today.year)
                                           .order(:number))
  end

  # returns the current week, from the specified array of weeks, based on the weeks' start times
  def get_current_week_from_weeks(weeks)
    now = DateTime.now
    weeks.each { |week|
      if now < week.start_time
        return (week.number - 1)
      end
    }
    return weeks.last.number
  end
end
