class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  helper_method :current_user
  helper_method :current_week
  helper_method :game_week
  before_filter :set_time_zone

  private

  # returns the current logged-in user
  def current_user
    @current_user ||= User.find_by_auth_token(cookies[:auth_token]) if cookies[:auth_token]
  end

  # sets the time zone to the time zone of the current user
  def set_time_zone
    Time.zone = current_user.time_zone if current_user
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

  def get_current_week_object_from_weeks(weeks)
    now = DateTime.now
    weeks.each { |week|
      if now < week.start_time
        return week
      end
    }
    return weeks.last
  end

  # returns the week number based on whether any games in that particular week have already started
  def game_week
    now = DateTime.now
    all_games = NflSchedule.where(year: Date.today.year)
                           .order(:start_time)
    week_started = 0
    all_games.each { |game|
      if (week_started < game.week) && (now > game.start_time)
        week_started = game.week
      end
    }
    return week_started
  end
end
