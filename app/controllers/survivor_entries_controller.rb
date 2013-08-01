class SurvivorEntriesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /dashboard
  def dashboard
    @user = current_user
    if !@user.nil?
      current_year = Date.today.year
      @type_to_entry_map = build_type_to_entry_map(
          SurvivorEntry.where({user_id: @user.id, year: current_year})
                       .order(:game_type, :entry_number))

      user_bets = SurvivorBet.includes([:nfl_game, :nfl_team])
                             .joins(:survivor_entry)
                             .joins(:nfl_game)
                             .where(:survivor_entries => {year: current_year, user_id: @user.id})
                             .order("survivor_entries.id, nfl_schedules.week")
      @entry_to_bets_map = build_entry_id_to_bets_map(user_bets)
    else
      redirect_to root_url
    end
  end

  # GET /my_entries
  def my_entries
    @user = current_user
    if !@user.nil?
      # before_season depends on start of season
      @before_season =
          DateTime.now < Week.where({year: Date.today.year, number: 1}).first.start_time

      current_year = Date.today.year
      @type_to_entry_map = build_type_to_entry_map(
          SurvivorEntry.where({user_id: @user.id, year: current_year})
                       .order(:game_type, :entry_number))
    else
      redirect_to root_url
    end
  end

  # Returns a hash of survivor entry id to an array of bets for that entry
  def build_entry_id_to_bets_map(bets)
    entry_to_bets_map = {}
    bets.each do |bet|
      if entry_to_bets_map.has_key?(bet.survivor_entry_id)
        entry_to_bets_map[bet.survivor_entry_id] << bet
      else
        entry_to_bets_map[bet.survivor_entry_id] = [bet]
      end
    end
    return entry_to_bets_map
  end

  # Returns a hash of survivor entry game type to an array of the entries of that type
  def build_type_to_entry_map(entries)
    type_to_entry_map = {}
    entries.each do |entry|
      game_type = SurvivorEntry.name_to_game_type(entry.game_type)
      if type_to_entry_map.has_key?(game_type)
        type_to_entry_map[game_type] << entry
      else
        type_to_entry_map[game_type] = [entry]
      end
    end
    return type_to_entry_map
  end

  # POST /my_entries
  def save_entries
    @user = current_user
    if !@user.nil?
      is_updated, has_creates = false
      if params["cancel"].nil?
        current_year = Date.today.year
        type_to_entry_map = build_type_to_entry_map(
            SurvivorEntry.where({user_id: @user.id, year: current_year}))

        # Update entry count for each game type.
        is_updated |= update_entries(:survivor, type_to_entry_map, params, current_year)
        is_updated |= update_entries(:anti_survivor, type_to_entry_map, params, current_year)
        is_updated |= update_entries(:high_roller, type_to_entry_map, params, current_year)

        SurvivorEntry::GAME_TYPE_ARRAY.each { |game_type|
          existing_entries = type_to_entry_map[game_type]
          existing_size = existing_entries.nil? ? 0 : existing_entries.size
          has_creates |= params["game_" + game_type.to_s].to_i > existing_size
        }
      end

      # re-direct user to my_entries page, with confirmation
      if is_updated
        confirmation_message = has_creates ?
            "Congratulations! Click on an individual entry to start making picks!" :
            "Entries successfully deleted!"
      end
      redirect_to my_entries_url, notice: confirmation_message
    else
      redirect_to root_url
    end
  end

  # Updates the number of entries for the specified game type, logged-in user & year, based on the
  # specified count and how many entries currently exist for the user.
  def update_entries(game_type, type_to_entry_map, params, year)
    # based on updated count, create new entries or delete existing
    existing_entries = type_to_entry_map[game_type]
    existing_size = existing_entries.nil? ? 0 : existing_entries.size
    updated_count = params["game_" + game_type.to_s].to_i
    
    if existing_size < updated_count
      # count is higher than existing, create the difference
      create_entries(existing_size, updated_count, year, game_type)
      return true
    elsif existing_size > updated_count
      # existing is higher than count, delete the difference
      destroy_entries(existing_entries, (existing_size - updated_count))
      return true
    end
    return false
  end

  # Creates entries of the specified game type, for the specified year, for the logged-in user. so
  # that the user now has updated_count entries.
  def create_entries(existing_size, updated_count, year, game_type)
    (existing_size + 1).upto(updated_count) { |entry_number|
      new_entry = SurvivorEntry.new
      new_entry.user_id = current_user.id
      new_entry.year = year
      new_entry.game_type = game_type
      new_entry.entry_number = entry_number
      new_entry.is_alive = true
      new_entry.used_autopick = false
      new_entry.save
    }
  end

  # Destroys the specified number of entries from the specified array of entries, including all bets
  # currently made for this entry.
  def destroy_entries(existing_entries, num_to_destroy)
    start_idx = existing_entries.size - 1
    end_idx = start_idx - num_to_destroy + 1
    start_idx.downto(end_idx) { |destroy_idx|
      entry_to_destroy = existing_entries[destroy_idx]

      # if entry has any bets, first destroy them.
      bets = SurvivorBet.where(survivor_entry_id: entry_to_destroy)
      bets.each { |bet|
        bet.destroy
      }

      # then, destroy entry
      entry_to_destroy.destroy
    }
  end

  # GET /survivor_entries
  # GET /survivor_entries.json
  def index
    @survivor_entries = SurvivorEntry.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @survivor_entries }
    end
  end

  # GET /survivor_entries/1
  # GET /survivor_entries/1.json
  def show
    # if logged-in user doesn't own entry, then redirect to home page.
    @user = current_user
    begin
      @survivor_entry = SurvivorEntry.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      redirect_to root_url
      return
    end

    if !@user.nil? && !@survivor_entry.nil? && @survivor_entry.user_id == @user.id
      @selector_to_bet_map = build_selector_to_bet_map(
            SurvivorBet.includes(:nfl_game)
                       .where(survivor_entry_id: @survivor_entry))
      
      current_year = Date.today.year
      @week_team_to_game_map = build_week_team_to_game_map(NflSchedule.where(year: current_year))
      @nfl_teams_map = build_id_to_team_map(NflTeam.order(:city, :name))
      @weeks = Week.where(year: Date.today.year)
                   .where("number <= (?)", @survivor_entry.max_weeks)
                   .order(:number)
      @week_to_start_time_map = build_week_to_start_time_map(@weeks)
      @current_week = get_current_week_from_weeks(@weeks)

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @survivor_entry }
      end
    else
      redirect_to root_url
    end
  end

  # returns a map of team id to nfl team
  def build_id_to_team_map(teams)
    id_to_team_map = {}
    teams.each { |team|
      id_to_team_map[team.id] = team
    }
    return id_to_team_map
  end

  # returns a map of week and bet number to the corresponding existing bet.
  def build_selector_to_bet_map(bets)
    selector_to_bet_map = {}
    bets.each { |bet|
      selector_to_bet_map[bet.selector] = bet
    }
    return selector_to_bet_map
  end
  
  # returns a map of a key containing week number and nfl team id to the game during that week, with
  # that team playing
  def build_week_team_to_game_map(nfl_games)
    week_team_to_game_map = {}
    nfl_games.each { |game|
      week_team_to_game_map[game.home_selector] = game
      week_team_to_game_map[game.away_selector] = game
    }
    return week_team_to_game_map
  end
 
  # returns a map of week number to start_time for that week
  def build_week_to_start_time_map(weeks)
    week_to_start_time_map = {}
    weeks.each { |week|
      week_to_start_time_map[week.number] = week.start_time
    }
    return week_to_start_time_map
  end

  # POST /save_entry_bets
  def save_entry_bets
    # if logged-in user doesn't own entry, then redirect to home page.
    @user = current_user
    @survivor_entry = SurvivorEntry.find(params[:id])
    if !@user.nil? && !@survivor_entry.nil? && @survivor_entry.user_id == @user.id
      # save created/updated bets for selected entry
      if params["cancel"].nil?
        current_year = Date.today.year
        selector_to_bet_map = build_selector_to_bet_map(
            SurvivorBet.where(survivor_entry_id: @survivor_entry))
        week_team_to_game_map = build_week_team_to_game_map(
            NflSchedule.where(year: current_year))

        game_type = SurvivorEntry.name_to_game_type(@survivor_entry.game_type)
        bets_to_create = []
        bets_to_update = []
        1.upto(SurvivorEntry::MAX_WEEKS_MAP[game_type]) { |week|
          1.upto(SurvivorEntry.bets_in_week(game_type, week)) { |bet_number|
            selector = SurvivorBet.bet_selector(week, bet_number)
            existing_bet = selector_to_bet_map[selector]
            selected_team_id = params[selector].to_i
            if !params[selector].nil? &&
                (!existing_bet.nil? || selected_team_id > 0)
              if existing_bet.nil?
                # Bet does not exist, create new bet.
                new_bet = SurvivorBet.new
                new_bet.survivor_entry_id = @survivor_entry.id
                new_bet.week = week
                new_bet.bet_number = bet_number
                new_bet.nfl_game_id =
                    week_team_to_game_map[NflSchedule.game_selector(week, selected_team_id)].id
                new_bet.nfl_team_id = selected_team_id
                new_bet.is_correct = nil
                bets_to_create << new_bet
              elsif existing_bet.nfl_team_id != selected_team_id
                # Bet already exists and is changed, update.
                existing_bet.nfl_team_id = selected_team_id
                existing_bet.nfl_game_id = selected_team_id == 0 ? 0 :
                    week_team_to_game_map[NflSchedule.game_selector(week, selected_team_id)].id
                bets_to_update << existing_bet
              end
            end
          }
        }

        # Bulk-save all bets at once; show error if same team is selected multiple times for one
        # entry.
        confirmation_message = ""
        if !bets_to_create.empty? || !bets_to_update.empty?
          # Wrap creates/updates/deletes in a single transaction, in case any of the operations
          # violates an index, at which point all of the operations are rolled back.
          SurvivorBet.transaction do 
            begin
              # First, bulk-import new bets
              import_result = SurvivorBet.import bets_to_create

              # Next, update each existing bet, deleting if no team is selected
              bets_to_update.each { |bet_to_update|
                if bet_to_update.nfl_team_id > 0
                  bet_to_update.save
                else
                  bet_to_update.destroy
                end
              }

              if import_result.failed_instances.empty?
                confirmation_message = "Picks successfully updated!"
                # send bet summary email if user receives emails
                if @user.send_emails
                  UserMailer.survivor_bet_summary(
                      @user, bets_to_create, bets_to_update, week_team_to_game_map).deliver
                end
              else
                confirmation_message = "Error: Failed instances while saving bets"
              end
            rescue Exception => e
              confirmation_message = "Error: Cannot select same team twice."
            end
          end
        end
      end
      redirect_to "/survivor_entries/" + @survivor_entry.id.to_s, notice: confirmation_message
    else
      redirect_to root_url
    end
  end

  # GET /survivor_entries/new
  # GET /survivor_entries/new.json
  def new
    @survivor_entry = SurvivorEntry.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @survivor_entry }
    end
  end

  # GET /survivor
  def survivor
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end

    @game_type = :survivor
    load_entries_data(@game_type)
    render "breakdown"
  end

  # GET /anti_survivor
  def anti_survivor
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end

    @game_type = :anti_survivor
    load_entries_data(@game_type)
    render "breakdown"
  end

  # GET /high_roller
  def high_roller
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end

    @game_type = :high_roller
    load_entries_data(@game_type)
    render "breakdown"
  end

  # loads the survivor entry data for the game breakdown by the specified game_type
  def load_entries_data(game_type)
    @entries_by_type = get_entries_by_type(game_type)
    @entry_to_bets_map = get_bets_map_by_type(game_type)
    @current_week = get_current_week
    @game_week = game_week
    @week_to_entry_stats_map = build_week_to_entry_stats_map(@entries_by_type, @current_week)
  end

  # returns the survivor entries of the specified type
  def get_entries_by_type(game_type)
    return SurvivorEntry.includes(:user)
                        .joins(:user)
                        .where({year: Date.today.year, game_type: game_type})
                        .order("survivor_entries.knockout_week DESC, users.last_name,
                                users.first_name, survivor_entries.entry_number")
  end

  # returns the survivor bets of the specified type, in a map of entry to bet
  def get_bets_map_by_type(game_type)
    return build_entry_to_bets_map(
        SurvivorBet.includes([:nfl_game, :nfl_team])
                   .joins(:survivor_entry)
                   .joins(:nfl_game)
                   .where(:survivor_entries => {year: Date.today.year, game_type: game_type})
                   .order("survivor_entries.id, nfl_schedules.week"))
  end

  # returns a map of entry id to another map of week/bet-number for the corresponding bet belonging
  # to that entry.
  def build_entry_to_bets_map(bets)
    entry_to_bets_map = {}
    bets.each { |bet|
      if !entry_to_bets_map.has_key?(bet.survivor_entry_id)
        entry_to_bets_map[bet.survivor_entry_id] = {}
      end
      entry_to_bets_map[bet.survivor_entry_id][bet.selector] = bet
    }
    return entry_to_bets_map
  end

  # returns the current week of all weeks for the given year
  def get_current_week
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

  # returns a map of week (up to the specified current week) to another hash, including stats for
  # total entries alive during that week & number of entries eliminated during that week.
  def build_week_to_entry_stats_map(entries_by_type, current_week)
    week_to_entry_stats_map = {}
    1.upto(current_week) { |week|
      week_to_entry_stats_map[week] = {}
      week_to_entry_stats_map[week]["alive"] = 0
      week_to_entry_stats_map[week]["elim"] = 0
    }

    entries_by_type.each { |entry|
      1.upto(current_week) { |week|
        if entry.is_alive || entry.knockout_week >= week
          week_to_entry_stats_map[week]["alive"] += 1
        end
        if entry.knockout_week == week
          week_to_entry_stats_map[week]["elim"] += 1
        end
      }
    }
    return week_to_entry_stats_map
  end

  # GET /entry_counts
  def all_entries
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end
    
    @users = User.order("lower (last_name), lower(first_name)")
    @current_year = Date.today.year
    entries = SurvivorEntry.where(year: @current_year)
    @user_to_entries_count_map = {}
    init_entry_count_map(@user_to_entries_count_map, 0)
    entries.each { |entry|
      if !@user_to_entries_count_map.has_key?(entry.user_id)
        init_entry_count_map(@user_to_entries_count_map, entry.user_id)
      end
      @user_to_entries_count_map[entry.user_id][entry.get_game_type][0] += 1
      @user_to_entries_count_map[0][entry.get_game_type][0] += 1
      if entry.is_alive
        @user_to_entries_count_map[entry.user_id][entry.get_game_type][1] += 1
        @user_to_entries_count_map[0][entry.get_game_type][1] += 1
      end
    }
  end

  def init_entry_count_map(entry_count_map, user_id)
    entry_count_map[user_id] = {}
    entry_count_map[user_id][:survivor] = [0,0]
    entry_count_map[user_id][:anti_survivor] = [0,0]
    entry_count_map[user_id][:high_roller] = [0,0]
  end

  # GET /kill_entries
  def kill_entries
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end
    @current_year = Date.today.year
    @current_week = current_week
    @selected_week = @current_week
  end

  # GET /kill_entries/week/:number
  def kill_entries_week
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end
    @current_year = Date.today.year
    @current_week = current_week
    @selected_week = params[:number].to_i
    
    render "kill_entries"
  end 

  # GET /ajax/kill_entries/week/:number
  def ajax_kill_week
    # only let user see weeks that have completed
    @week = Week.where({year: Date.today.year, number: params[:number].to_i}).first
    if @week && DateTime.now > @week.start_time
      @entries_without_bets = get_entries_without_bets(@week.number)
    end
    render :layout => "ajax"
  end

  # DELETE /kill_entries/week/:number
  def kill_all
    week_number = params[:number].to_i
    @entries_without_bets = get_entries_without_bets(week_number)
    
    confirmation_message = ""
    SurvivorEntry.transaction {
      begin
        @entries_without_bets.each { |entry|
          entry.update_attributes({is_alive: false, knockout_week: week_number})
        }
      rescue Exception => e
        confirmation_message = "Error: Unexpected problem occurred while killing entries"
      end
      confirmation_message = "Entries successfully killed!"
    }

    redirect_to "/kill_entries/week/" + week_number.to_s, notice: confirmation_message
  end

  # returns the entries which do not have bets during the specified week, which are currently alive,
  # or were killed during the specified week.
  def get_entries_without_bets(week)
    entry_ids_for_week = SurvivorBet.where(week: week)
                                    .select(:survivor_entry_id)
                                    .collect { |bet| bet.survivor_entry_id }
    return SurvivorEntry.includes(:user)
                        .where(year: Date.today.year)
                        .where("id not in (?)", entry_ids_for_week)
                        .where("is_alive = true OR knockout_week = " + week.to_s)
  end
end
