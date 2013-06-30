class SurvivorEntriesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /survivor
  def dashboard
    @user = current_user
    if !@user.nil?
      # TODO set beforeSeason based on start of season [9/5?]
      @before_season = true

      current_year = Date.today.year
      user_bets = SurvivorBet.includes([:nfl_schedule, :nfl_team])
                             .joins(:survivor_entry)
                             .where(:survivor_entries => {year: current_year, user_id: @user.id})

      # TODO convert list of bets to type-to-entry map
      @type_to_entry_map = build_type_to_entry_map(
          SurvivorEntry.where({user_id: @user.id, year: current_year}))

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
      if entry_to_bets_map.has_key?(bet.survivor_entry.id)
        entry_to_bets_map[bet.survivor_entry.id] << bet
      else
        entry_to_bets_map[bet.survivor_entry.id] = [bet]
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
      create_entries((updated_count - existing_size), year, game_type)
      return true
    elsif existing_size > updated_count
      # existing is higher than count, delete the difference
      destroy_entries(existing_entries, (existing_size - updated_count))
      return true
    end
    return false
  end

  # Creates the specified number of entries of the specified game type, for the specified year, for
  # the logged-in user.
  def create_entries(num_to_create, year, game_type)
    1.upto(num_to_create) { |entry_count|
      new_entry = SurvivorEntry.new
      new_entry.user_id = current_user.id
      new_entry.year = year
      new_entry.game_type = game_type
      new_entry.is_alive = true
      new_entry.used_autopick = false
      new_entry.save
    }
  end

  # Destroys the specified number of entries from the specified array of entries.
  def destroy_entries(existing_entries, num_to_destroy)
    0.upto((num_to_destroy - 1)) { |destroy_idx|
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
    @survivor_entry = SurvivorEntry.find(params[:id])
    if !@user.nil? && !@survivor_entry.nil? && @survivor_entry.user_id == @user.id
      @survivor_bets = SurvivorBet.where(survivor_entry: @survivor_entry)
      
      # TODO filter selectable teams that haven't been selected for this entry
      current_year = Date.today.year
      
      # TODO need week_to_game_map? maybe for schedule?
      #@week_to_game_map = build_week_to_game_map(
      #    NflSchedule.includes([:home_nfl_team, :away_nfl_team])
      #               .where(year: current_year)
      #               .order(:week, :start_time))

      @team_to_games_map = build_team_to_games_map(NflSchedule.where(year: current_year))
      @nfl_teams = NflTeam.order(:city, :name)
      
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @survivor_entry }
      end
    else
      redirect_to root_url
    end
  end

  # returns a map of nfl team id to another hash, which is a map of week to game played during that
  # week
  def build_team_to_games_map(nfl_games)
    team_to_games_map = {}
    nfl_games.each { |game|
      if !team_to_games_map.has_key?(game.home_nfl_team_id)
        team_to_games_map[game.home_nfl_team_id] = {}
      end
      team_to_games_map[game.home_nfl_team_id][game.week] = game

      if !team_to_games_map.has_key?(game.away_nfl_team_id)
        team_to_games_map[game.away_nfl_team_id] = {}
      end
      team_to_games_map[game.away_nfl_team_id][game.week] = game
    }   
    return team_to_games_map
  end

  def build_week_to_game_map(nfl_games)
    week_to_game_map = {}
    nfl_games.each { |game|
      if week_to_game_map.has_key?(game.week)
        week_to_game_map[game.week] << game
      else
        week_to_game_map[game.week] = [game]
      end
    }
    return week_to_game_map
  end

  # POST /save_entry
  def save_entry
    # if logged-in user doesn't own entry, then redirect to home page.
    @user = current_user
    @survivor_entry = SurvivorEntry.find(params[:id])
    if !@user.nil? && !@survivor_entry.nil? && @survivor_entry.user_id == @user.id
      # TODO save updated bets for selected entry
      is_updated = false

      # re-direct user to individual entry page, with confirmation
      if is_updated
        confirmation_message = "Bets successfully updated!"
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

  # GET /survivor_entries/1/edit
  def edit
    @survivor_entry = SurvivorEntry.find(params[:id])
  end

  # POST /survivor_entries
  # POST /survivor_entries.json
  def create
    @survivor_entry = SurvivorEntry.new(params[:survivor_entry])

    respond_to do |format|
      if @survivor_entry.save
        format.html { redirect_to @survivor_entry, notice: 'Survivor entry was successfully created.' }
        format.json { render json: @survivor_entry, status: :created, location: @survivor_entry }
      else
        format.html { render action: "new" }
        format.json { render json: @survivor_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /survivor_entries/1
  # PUT /survivor_entries/1.json
  def update
    @survivor_entry = SurvivorEntry.find(params[:id])

    respond_to do |format|
      if @survivor_entry.update_attributes(params[:survivor_entry])
        format.html { redirect_to @survivor_entry, notice: 'Survivor entry was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @survivor_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /survivor_entries/1
  # DELETE /survivor_entries/1.json
  def destroy
    @survivor_entry = SurvivorEntry.find(params[:id])
    @survivor_entry.destroy

    respond_to do |format|
      format.html { redirect_to survivor_entries_url }
      format.json { head :no_content }
    end
  end
end
