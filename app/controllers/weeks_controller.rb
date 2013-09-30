class WeeksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /weeks
  # GET /weeks.json
  def index
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_super_admin
      redirect_to root_url
      return
    end

    @current_year = Date.today.year
    @weeks = Week.where(year: @current_year).order(:number)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @weeks }
    end
  end

  # POST /weeks
  def update
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_super_admin
      redirect_to root_url
      return
    end

    # update start times
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

  # GET /survivor/week
  def survivor
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end

    @game_type = :survivor
    @current_week = current_week
    @game_week = game_week
    render "breakdown"
  end

  # GET /ajax/survivor/week/:number
  def ajax_survivor
    load_week_breakdown_data(:survivor)
    render "ajax_breakdown", :layout => "ajax"
  end

  # GET /anti_survivor/week
  def anti_survivor
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end

    @game_type = :anti_survivor
    @current_week = current_week
    @game_week = game_week
    render "breakdown"
  end

    # GET /ajax/anti_survivor/week/:number
  def ajax_anti_survivor
    load_week_breakdown_data(:anti_survivor)
    render "ajax_breakdown", :layout => "ajax"
  end

  # GET /high_roller/week
  def high_roller
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end

    @game_type = :high_roller
    @current_week = current_week
    @game_week = game_week
    render "breakdown"
  end
  
  # GET /ajax/high_roller/week/:number
  def ajax_high_roller
    load_week_breakdown_data(:high_roller)
    render "ajax_breakdown", :layout => "ajax"
  end

  # GET /second_chance/week
  def second_chance
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end

    @game_type = :second_chance
    @current_week = current_week
    @game_week = game_week
    render "breakdown"
  end
  
  # GET /ajax/second_chance/week/:number
  def ajax_second_chance
    load_week_breakdown_data(:second_chance)
    render "ajax_breakdown", :layout => "ajax"
  end

  # loads the data for the week breakdown for the specified game_type
  def load_week_breakdown_data(game_type)
    # only let user see weeks that have completed
    @week = Week.where({year: Date.today.year, number: params[:id].to_i}).first
    if @week.nil?
      return
    end

    @current_week = current_week
    @team_map = build_team_map
    game_bets = get_game_bets(game_type, @week.number, Date.today.year)
    team_to_bet_counts_map = game_bets.group(:nfl_team_id).count(:nfl_team_id)
    @team_to_results_map = build_team_to_results_map(game_bets, team_to_bet_counts_map)
    @killed_entries = get_killed_entries(game_bets, @week.number, game_type)
  end
  
  # returns a map of nfl team id to corresponding team
  def build_team_map
    team_map = {}
    NflTeam.all.each { |team|
      team_map[team.id] = team
    }
    return team_map
  end

  # returns the bets of the specified game type during the specified week/year, belonging to entries
  # which have not been knocked out or were knocked out in the specified week
  def get_game_bets(game_type, week, year)
    return SurvivorBet.includes(:nfl_game)
                      .joins(:survivor_entry)
                      .joins(:user)
                      .where({week: week, :survivor_entries => {year: year, game_type: game_type}})
                      .where("survivor_entries.knockout_week IS NULL OR 
                              survivor_entries.knockout_week >= " + week.to_s)
  end

  # returns a hash of team id to the another hash including the results of bets on that team,
  # including the number of bets, whether the bets were correct, the team's opponent and the result
  # of the matchup. note that this method must take an array of bets which were made for the same
  # game type, during the same week.
  def build_team_to_results_map(game_bets, team_to_bet_counts_map)
    team_to_results_map = {}
    game_bets.each { |bet|
      if !team_to_results_map.has_key?(bet.nfl_team_id)
        team_to_results_map[bet.nfl_team_id] = {}
        team_to_results_map[bet.nfl_team_id]["count"] = team_to_bet_counts_map[bet.nfl_team_id]
        team_to_results_map[bet.nfl_team_id]["is_correct"] = bet.is_correct
        team_to_results_map[bet.nfl_team_id]["oppo_id"] =
            bet.nfl_game.opponent_team_id(bet.nfl_team_id)
        team_to_results_map[bet.nfl_team_id]["result"] = bet.game_result
        team_to_results_map[bet.nfl_team_id]["start_time"] = bet.nfl_game.start_time
      end
    }
    return team_to_results_map
  end

  # returns the entries that were killed during the specified week, i.e. those entries where
  # is_alive = false, knockout_week = week_number and are missing bets for the specified week.
  def get_killed_entries(game_bets, week_number, game_type)
    entries = SurvivorEntry.includes(:user)
                           .joins(:user)
                           .where({year: Date.today.year, game_type: game_type})
    entry_id_to_bets_map = build_entry_id_to_bets_map(game_bets)

    killed_entries = []
    entries.each { |entry|
      if !entry.is_alive && entry.knockout_week == week_number &&
          entry_missing_pick_in_week(entry, week_number, entry_id_to_bets_map)
        killed_entries << entry
      end
    }
    return killed_entries
  end
end
