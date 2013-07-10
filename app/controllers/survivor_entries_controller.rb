class SurvivorEntriesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /dashboard
  def dashboard
    @user = current_user
    if !@user.nil?
      # TODO set beforeSeason based on start of season [9/5?]
      @before_season = true

      current_year = Date.today.year
      @type_to_entry_map = build_type_to_entry_map(
          SurvivorEntry.where({user_id: @user.id, year: current_year}))

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
      # TODO before_season depends on start of season [9/5]
      @before_season = true

      current_year = Date.today.year
      @type_to_entry_map = build_type_to_entry_map(
          SurvivorEntry.where({user_id: @user.id, year: current_year}))
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
      is_updated = false
      if params["cancel"].nil?
        current_year = Date.today.year
        type_to_entry_map = build_type_to_entry_map(
            SurvivorEntry.where({user_id: @user.id, year: current_year}))

        # Update entry count for each game type.
        is_updated |= update_entries(:survivor, type_to_entry_map, params, current_year)
        is_updated |= update_entries(:anti_survivor, type_to_entry_map, params, current_year)
        is_updated |= update_entries(:high_roller, type_to_entry_map, params, current_year)
      end

      # re-direct user to my_entries page, with confirmation
      if is_updated
        confirmation_message = "Entry counts successfully updated!"
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

  # Destroys the specified number of entries from the specified array of entries.
  # TODO destroy corresponding bets, if they exist
  def destroy_entries(existing_entries, num_to_destroy)
    start_idx = existing_entries.size - 1
    end_idx = start_idx - num_to_destroy + 1
    start_idx.downto(end_idx) { |destroy_idx|
      existing_entries[destroy_idx].destroy
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
            SurvivorBet.where(survivor_entry_id: @survivor_entry))
      
      current_year = Date.today.year
      @week_team_to_game_map = build_week_team_to_game_map(NflSchedule.where(year: current_year))
      @nfl_teams_map = build_id_to_team_map(NflTeam.order(:city, :name))
      
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
    if !@user.nil?
      @entries_by_type = get_entries_by_type(:survivor)
      @entry_to_bets_map = get_bets_map_by_type(:survivor)
    else
      redirect_to root_url
    end
  end

  # GET /anti_survivor
  def anti_survivor
    @user = current_user
    if !@user.nil?
      @entries_by_type = get_entries_by_type(:anti_survivor)
      @entry_to_bets_map = get_bets_map_by_type(:anti_survivor)
    else
      redirect_to root_url
    end
  end

  # GET /high_roller
  def high_roller
    @user = current_user
    if !@user.nil?
      @entries_by_type = get_entries_by_type(:high_roller)
      @entry_to_bets_map = get_bets_map_by_type(:high_roller)
    else
      redirect_to root_url
    end
  end

  # returns the survivor entries of the specified type
  def get_entries_by_type(game_type)
    # TODO sort by the week when entry was knocked out
    return SurvivorEntry.includes(:user)
                        .joins(:user)
                        .where({year: Date.today.year, game_type: game_type})
                        .order("users.last_name, users.first_name, survivor_entries.entry_number")
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
end
