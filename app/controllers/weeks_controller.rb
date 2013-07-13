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

  # GET /survivor/week/:id
  def survivor
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end
    # TODO only let user see weeks that have completed
    # TODO show whether teams won/lost, including totals
    # TODO add support for anti, highroll
    @week = Week.where(number: params[:id].to_i).first
    @team_map = build_team_map
    @team_to_bet_counts_map = build_team_to_bet_counts_map(:survivor, @week.number, Date.today.year)
  end

  def build_team_to_bet_counts_map(game_type, week, year)
    return SurvivorBet.joins(:survivor_entry)
                      .where({week: week, :survivor_entries => {year: year, game_type: game_type}})
                      .group(:nfl_team_id)
                      .count(:nfl_team_id)
  end

  def build_team_map
    team_map = {}
    NflTeam.all.each { |team|
      team_map[team.id] = team
    }
    return team_map
  end
end
