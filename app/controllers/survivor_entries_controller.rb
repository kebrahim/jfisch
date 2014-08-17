class SurvivorEntriesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /dashboard
  def dashboard
    @user = current_user
    if !@user.nil?
      get_dashboard_data(@user)
    else
      redirect_to root_url
    end
  end

  # GET /users/:user_id/dashboard
  def user_dashboard
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    @admin_function = true
    @user = User.find_by_id(params[:user_id])
    if !@user.nil?
      get_dashboard_data(@user)
      render "dashboard"
    else
      redirect_to root_url
    end
  end

  # loads the data needed for the dashboard, for the specified user
  def get_dashboard_data(user)
    @before_season =
        DateTime.now < Week.where({year: current_season_year, number: 1}).first.start_time
    current_year = current_season_year
    @current_week = get_next_week_object_from_weeks(
        Week.where(year: current_season_year).order(:number))
    @type_to_entry_map = build_type_to_entry_map(
        SurvivorEntry.where({user_id: user.id, year: current_year})
                     .order(:game_type, :entry_number))

    user_bets = SurvivorBet.includes([:nfl_game, :nfl_team])
                           .joins(:survivor_entry)
                           .joins(:nfl_game)
                           .where(:survivor_entries => {year: current_year, user_id: user.id})
                           .order("survivor_entries.id, nfl_schedules.week")
    @entry_to_bets_map = build_entry_id_to_bets_map(user_bets)
    @total_counts = SurvivorEntry.group(:game_type).count
    @alive_counts = SurvivorEntry.where(is_alive: true).group(:game_type).count
  end

  # GET /my_entries
  def my_entries
    @user = current_user
    if !@user.nil?
      get_entries_data(@user)
    else
      redirect_to root_url
    end
  end

  # GET /users/:user_id/entries
  def user_entries
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    @admin_function = true
    @user = User.find_by_id(params[:user_id])
    if !@user.nil?
      get_entries_data(@user)
      render "my_entries"
    else
      redirect_to root_url
    end
  end

  # Loads the data needed for the my_entries page, for the specified user
  def get_entries_data(user)
    # before_season depends on start of season
    @before_season = get_before_season_map(user)

    current_year = current_season_year
    @type_to_entry_map = build_type_to_entry_map(
        SurvivorEntry.where({user_id: user.id, year: current_year})
                     .order(:game_type, :entry_number))

    user_bets = SurvivorBet.includes([:nfl_game, :nfl_team])
                           .joins(:survivor_entry)
                           .joins(:nfl_game)
                           .where(:survivor_entries => {year: current_year, user_id: user.id})
                           .order("survivor_entries.id, nfl_schedules.week")
    @selector_to_bet_map = build_entry_selector_to_bet_map(user_bets)
    @week_team_to_game_map = build_week_team_to_game_map(NflSchedule.where(year: current_year))
    @nfl_teams_map = build_id_to_team_map(NflTeam.order(:city, :name))

    @weeks = Week.where(year: current_season_year)
                 .order(:number)
    @week_to_start_time_map = build_week_to_start_time_map(@weeks)
    @current_week = get_current_week_from_weeks(@weeks)
  end

  # returns a hash of game type to boolean depending on whether the season has begun for that game
  def get_before_season_map(user)
    before_season = {}
    SurvivorEntry::GAME_TYPE_ARRAY.each { |game_type|
      before_season[game_type] = (DateTime.now <
          Week.where({ year: current_season_year,
                       number: SurvivorEntry::START_WEEK_MAP[game_type]}).first.start_time) &&
          ((game_type != :second_chance) || !user.is_blacklisted)
    }
    return before_season
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
      # update entries or bets, depending on which button was pressed
      confirmation_message = update_user_entries_and_bets(@user, params)

      # if error occurs, re-direct to my_entries page, otherwise to dashboard
      if confirmation_message.starts_with?("Error:")
        redirect_to my_entries_url, notice: confirmation_message
      else
        redirect_to dashboard_url, notice: confirmation_message
      end
    else
      redirect_to root_url
    end
  end

  # POST /user_entries/:user_id
  def save_user_entries
    @admin_function = true
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    @user = User.find_by_id(params[:user_id])
    if !@user.nil?
      # update entries or bets for impersonated user, depending on which button was pressed
      confirmation_message = update_user_entries_and_bets(@user, params)

      # if error occurs, re-direct to user entries page, otherwise to user dashboard
      if confirmation_message.starts_with?("Error:")
        redirect_to "/users/" + @user.id.to_s + "/entries", notice: confirmation_message
      else
        redirect_to "/users/" + @user.id.to_s + "/dashboard", notice: confirmation_message
      end
    else
      redirect_to root_url
    end
  end

  # Updates the specified user's entry counts and picks, based on the specified posted params
  def update_user_entries_and_bets(user, params)
    confirmation_message = ""
    current_year = current_season_year
    if params["updateentries"]
      is_updated, has_creates = false
      type_to_entry_map = build_type_to_entry_map(
          SurvivorEntry.where({user_id: user.id, year: current_year})
                       .order(:game_type, :entry_number))

      # Update entry count for each game type only if season hasn't started for game type.
      before_season = get_before_season_map(user)
      SurvivorEntry::GAME_TYPE_ARRAY.each { |game_type|
        if before_season[game_type]
          is_updated |= update_entries(game_type, user, type_to_entry_map, params, current_year)
        end
      }

      SurvivorEntry::GAME_TYPE_ARRAY.each { |game_type|
        existing_entries = type_to_entry_map[game_type]
        existing_size = existing_entries.nil? ? 0 : existing_entries.size
        has_creates |= params["game_" + game_type.to_s].to_i > existing_size
      }
      if is_updated
        confirmation_message = has_creates ?
            "Congratulations! Click on an individual entry to start making picks!" :
            "Entries successfully deleted!"
      end
    elsif params["updatebets"]
      user_bets = SurvivorBet.includes([:nfl_game, :nfl_team])
                             .joins(:survivor_entry)
                             .joins(:nfl_game)
                             .where(:survivor_entries => {year: current_year, user_id: user.id})
                             .order("survivor_entries.id, nfl_schedules.week")
      selector_to_bet_map = build_entry_selector_to_bet_map(user_bets)
      week_team_to_game_map = build_week_team_to_game_map(NflSchedule.where(year: current_year))
      user_entries = SurvivorEntry.where({user_id: user.id, year: current_year})
                                  .order(:game_type, :entry_number)
      weeks = Week.where(year: current_season_year)
                  .order(:number)
      week_to_start_time_map = build_week_to_start_time_map(weeks)
      
      # collect bets, separating into create/update
      bets = {}
      bets[:create] = []
      bets[:update] = []
      user_entries.each { |survivor_entry|
        get_updated_bets(survivor_entry, bets, selector_to_bet_map, week_team_to_game_map,
                         week_to_start_time_map)
      }

      # create/update bets
      confirmation_message = create_update_bets(user, bets, week_team_to_game_map)
    end
    return confirmation_message
  end

  # creates/updates the specified bets for the specified user, emails that user if they have emails
  # enabled, and returns a confirmation message
  def create_update_bets(user, user_entry_bets, week_team_to_game_map)
    confirmation_message = ""
    if !user_entry_bets[:create].empty? || !user_entry_bets[:update].empty?
      # Wrap creates/updates/deletes in a single transaction, in case any of the operations
      # violates an index, at which point all of the operations are rolled back.
      SurvivorBet.transaction do 
        begin
          # First, bulk-import new bets
          import_result = SurvivorBet.import user_entry_bets[:create]

          # Next, update each existing bet, deleting if no team is selected
          user_entry_bets[:update].each { |bet_to_update|
            if bet_to_update.nfl_team_id > 0
              bet_to_update.save
            else
              bet_to_update.destroy
            end
          }

          if import_result.failed_instances.empty?
            confirmation_message = "Picks successfully updated!"
            # send bet summary email if user receives emails
            if user.send_emails
              UserMailer.survivor_bet_summary(user, user_entry_bets[:create],
                  user_entry_bets[:update], week_team_to_game_map).deliver
            end
          else
            confirmation_message = "Error: Failed instances while saving bets"
          end
        rescue Exception => e
          confirmation_message = "Error: Cannot select same team twice."
        end
      end
    end
    return confirmation_message
  end

  # constructs the bets to create/update/delete for the specified entry and populates them in the
  # specified bets hashmap
  def get_updated_bets(survivor_entry, bets, selector_to_bet_map, week_team_to_game_map,
                       week_to_start_time_map)
    game_type = SurvivorEntry.name_to_game_type(survivor_entry.game_type)
    1.upto(SurvivorEntry::MAX_WEEKS_MAP[game_type]) { |week|
      1.upto(SurvivorEntry.bets_in_week(game_type, week)) { |bet_number|
        selector = SurvivorBet.bet_entry_selector(survivor_entry.id, week, bet_number)
        existing_bet = selector_to_bet_map[selector]
        selected_team_id = params[selector].to_i
        if !params[selector].nil? &&
            (!existing_bet.nil? || selected_team_id > 0)
          if existing_bet.nil?
            # Bet does not exist, create new bet if game isn't locked.
            nfl_game = week_team_to_game_map[NflSchedule.game_selector(week, selected_team_id)]
            if !nfl_game.is_locked(week_to_start_time_map)
              new_bet = SurvivorBet.new
              new_bet.survivor_entry_id = survivor_entry.id
              new_bet.week = week
              new_bet.bet_number = bet_number
              new_bet.nfl_game_id = nfl_game.id
              new_bet.nfl_team_id = selected_team_id
              new_bet.is_correct = nil
              bets[:create] << new_bet
            end
          elsif existing_bet.nfl_team_id != selected_team_id
            # Bet already exists and is changed, update if neither previous nor currently
            # selected games are locked.
            new_nfl_game =
                week_team_to_game_map[NflSchedule.game_selector(week, selected_team_id)]
            old_nfl_game =
                week_team_to_game_map[NflSchedule.game_selector(week, existing_bet.nfl_team_id)]
            if !old_nfl_game.is_locked(week_to_start_time_map) &&
               (new_nfl_game.nil? || !new_nfl_game.is_locked(week_to_start_time_map))
              existing_bet.nfl_team_id = selected_team_id
              existing_bet.nfl_game_id = selected_team_id == 0 ? 0 : new_nfl_game.id
              bets[:update] << existing_bet
            end
          end
        end
      }
    }
  end

  # Updates the number of entries for the specified game type, user & year, based on the specified
  # count and how many entries currently exist for the user.
  def update_entries(game_type, user, type_to_entry_map, params, year)
    # based on updated count, create new entries or delete existing
    existing_entries = type_to_entry_map[game_type]
    existing_size = existing_entries.nil? ? 0 : existing_entries.size
    updated_count = params["game_" + game_type.to_s].to_i
    
    if existing_size < updated_count
      # count is higher than existing, create the difference
      create_entries(existing_size, updated_count, user, year, game_type)
      return true
    elsif existing_size > updated_count
      # existing is higher than count, delete the difference
      destroy_entries(existing_entries, (existing_size - updated_count))
      return true
    end
    return false
  end

  # Creates entries of the specified game type, for the specified year, for the specified user. so
  # that the user now has updated_count entries.
  def create_entries(existing_size, updated_count, user, year, game_type)
    (existing_size + 1).upto(updated_count) { |entry_number|
      new_entry = SurvivorEntry.new
      new_entry.user_id = user.id
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

      # destroy entry
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

    if !@user.nil? && !@survivor_entry.nil? &&
        (@survivor_entry.user_id == @user.id || @user.is_admin)
      @admin_function = @user.is_admin && (@survivor_entry.user_id != @user.id)
      @weeks = Week.where(year: current_season_year)
                   .where("number >= (?)", @survivor_entry.start_week)
                   .where("number <= (?)", @survivor_entry.max_weeks)
                   .order(:number)
      @current_week = get_current_week_from_weeks(@weeks)
      @user_entries = SurvivorEntry.where({ year: current_season_year,
                                            user_id: @survivor_entry.user_id })
                                   .order(:game_type, :entry_number)

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @survivor_entry }
      end
    else
      redirect_to root_url
    end
  end

  # GET /ajax/survivor_entries/:id
  def ajaxshow
    # if logged-in user doesn't own entry, then redirect to home page.
    @user = current_user
    begin
      @survivor_entry = SurvivorEntry.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      redirect_to root_url
      return
    end

    if !@user.nil? && !@survivor_entry.nil? &&
        (@survivor_entry.user_id == @user.id || @user.is_admin)
      @admin_function = @user.is_admin && (@survivor_entry.user_id != @user.id)
      @selector_to_bet_map = build_selector_to_bet_map(
            SurvivorBet.includes(:nfl_game)
                       .where(survivor_entry_id: @survivor_entry))
      
      current_year = current_season_year
      @week_team_to_game_map = build_week_team_to_game_map(NflSchedule.where(year: current_year))
      @nfl_teams_map = build_id_to_team_map(NflTeam.order(:city, :name))
      @weeks = Week.where(year: current_season_year)
                   .where("number <= (?)", @survivor_entry.max_weeks)
                   .order(:number)
      @week_to_start_time_map = build_week_to_start_time_map(@weeks)
      @current_week = get_current_week_from_weeks(@weeks)
    end

    render :layout => "ajax"
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

  # returns a map of entry-id/week/bet-number to the corresponding existing bet.
  def build_entry_selector_to_bet_map(bets)
    selector_to_bet_map = {}
    bets.each { |bet|
      selector_to_bet_map[bet.entry_selector] = bet
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
    if !@user.nil? && !@survivor_entry.nil? &&
        (@survivor_entry.user_id == @user.id || @user.is_admin)
      @admin_function = @user.is_admin && (@survivor_entry.user_id != @user.id)

      # save created/updated bets for selected entry
      if params["cancel"].nil?
        current_year = current_season_year
        selector_to_bet_map = build_selector_to_bet_map(
            SurvivorBet.where(survivor_entry_id: @survivor_entry))
        week_team_to_game_map = build_week_team_to_game_map(
            NflSchedule.where(year: current_year))
        weeks = Week.where(year: current_season_year)
                    .order(:number)
        week_to_start_time_map = build_week_to_start_time_map(weeks)

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
              # TODO validate bets [no repeats, locked games, etc.]; aggregate invalid bets
              if existing_bet.nil?
                # Bet does not exist, create new bet if game isn't locked.
                nfl_game = week_team_to_game_map[NflSchedule.game_selector(week, selected_team_id)]
                if !nfl_game.is_locked(week_to_start_time_map)
                  new_bet = SurvivorBet.new
                  new_bet.survivor_entry_id = @survivor_entry.id
                  new_bet.week = week
                  new_bet.bet_number = bet_number
                  new_bet.nfl_game_id = nfl_game.id
                  new_bet.nfl_team_id = selected_team_id
                  new_bet.is_correct = nil
                  bets_to_create << new_bet
                end
              elsif existing_bet.nfl_team_id != selected_team_id
                # Bet already exists and is changed, update if neither previous nor currently
                # selected games are locked.
                new_nfl_game =
                    week_team_to_game_map[NflSchedule.game_selector(week, selected_team_id)]
                old_nfl_game =
                    week_team_to_game_map[NflSchedule.game_selector(week, existing_bet.nfl_team_id)]
                if !old_nfl_game.is_locked(week_to_start_time_map) &&
                   (new_nfl_game.nil? || !new_nfl_game.is_locked(week_to_start_time_map))
                  existing_bet.nfl_team_id = selected_team_id
                  existing_bet.nfl_game_id = selected_team_id == 0 ? 0 : new_nfl_game.id
                  bets_to_update << existing_bet
                end
              end
            end
          }
        }

        # Bulk-save all bets at once; show error if same team is selected multiple times for one
        # entry.
        confirmation_message = ""
        # TODO if !invalid_bets.empty? highlight invalid bets, and save valid bets.
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
                if @survivor_entry.user.send_emails
                  UserMailer.survivor_bet_summary(@survivor_entry.user, bets_to_create,
                      bets_to_update, week_team_to_game_map).deliver
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
      
      if confirmation_message.starts_with?("Error:")
        redirect_to "/survivor_entries/" + @survivor_entry.id.to_s, notice: confirmation_message
      else
        redirect_to (@admin_function ?
            "/users/" + @survivor_entry.user_id.to_s + "/dashboard" : dashboard_url),
            notice: confirmation_message
      end
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
    load_breakdown(:survivor)
  end

  # GET /anti_survivor
  def anti_survivor
    load_breakdown(:anti_survivor)
  end

  # GET /high_roller
  def high_roller
    load_breakdown(:high_roller)
  end

  # GET /second_chance
  def second_chance
    load_breakdown(:second_chance)
  end

  def load_breakdown(game_type)
    @user = current_user
    if @user.nil? || (game_type == :second_chance && @user.is_blacklisted)
      redirect_to root_url
      return
    end

    @game_type = game_type
    load_entries_data(game_type)
    respond_to do |format|
      format.html { 
        render "breakdown"
      }
      format.csv {
        send_data to_csv(@entries_by_type, @entry_to_bets_map, @game_type, @current_week,
                         @game_week)
      }
      format.xls {
        max_week = [@current_week, @game_week].max
        @column_headers = get_column_headers(game_type, max_week)
        @column_values = get_column_values(
            game_type, @entries_by_type, @entry_to_bets_map, max_week)
        render "breakdown"
      }
    end
  end

  # loads the survivor entry data for the game breakdown by the specified game_type
  def load_entries_data(game_type)
    @entries_by_type = get_entries_by_type(game_type)
    @entry_to_bets_map = get_bets_map_by_type(game_type)
    @current_week = get_current_week
    @game_week = game_week
    @week_to_entry_stats_map =
        build_week_to_entry_stats_map(@entries_by_type, @game_week, game_type)
  end
  
  # returns the column headers for the entry breakdown table
  def get_column_headers(game_type, max_week)
    column_headers = ["Entry"]
    1.upto(max_week) { |week|
      if SurvivorEntry.bets_in_week(game_type, week) == 1
        column_headers << "Week " + week.to_s
      else
        column_headers << "Week " + week.to_s + "a"
        column_headers << "Week " + week.to_s + "b"
      end
    }
    return column_headers
  end

  def get_entry_key(entry)
    return entry.user.full_name + " " + entry.entry_number.to_s
  end
 
  # returns the column values for the entry breakdown table
  def get_column_values(game_type, entries, entry_to_bets_map, max_week)
    column_values = {}
    entries.each do |entry|
      entry_key = get_entry_key(entry)
      column_values[entry_key] = [entry_key]
      bets = entry_to_bets_map[entry.id]
      1.upto(max_week) { |week|
        1.upto(SurvivorEntry.bets_in_week(game_type, week)) { |bet_number|
          if !bets.nil?
            bet = bets[SurvivorBet.bet_selector(week, bet_number)]
            if !bet.nil?
              if entry.is_alive || week <= entry.knockout_week
                if !bet.is_correct.nil? || (DateTime.now > bet.nfl_game.start_time) ||
                    (bet.week <= current_week)
                  column_values[entry_key] << bet.nfl_team.abbreviation
                else
                  column_values[entry_key] << ""
                end
              else
                column_values[entry_key] << ""
              end
            elsif entry.knockout_week == week
              column_values[entry_key] << "--"
            else
              column_values[entry_key] << ""
            end
          elsif entry.knockout_week == week
            column_values[entry_key] << "--"
          end
        }
      }
    end
    return column_values
  end

  # converts the specified array of entries into a CSV file
  def to_csv(entries, entry_to_bets_map, game_type, current_week, game_week)
    CSV.generate do |csv|
      max_week = [current_week, game_week].max
      csv << get_column_headers(game_type, max_week)
      column_values = get_column_values(game_type, entries, entry_to_bets_map, max_week)
      entries.each do |entry|
        csv << column_values[get_entry_key(entry)]
      end
    end
  end

  # returns the survivor bets of the specified type, in a map of entry to bet
  def get_bets_map_by_type(game_type)
    return build_entry_to_bets_map(
        SurvivorBet.includes([:nfl_game, :nfl_team])
                   .joins(:survivor_entry)
                   .joins(:nfl_game)
                   .where(:survivor_entries => {year: current_season_year, game_type: game_type})
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
    return get_current_week_from_weeks(Week.where(year: current_season_year)
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

  # GET /entries
  def all_entries
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end
    
    @users = User.order("lower(first_name), lower (last_name)")
    @current_year = current_season_year
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

  # GET /entry_history
  def entry_history
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end
    
    @current_year = current_season_year
    @entries = SurvivorEntry.includes(:user)
                            .where(year: @current_year)
                            .order(:created_at)
  end

  def init_entry_count_map(entry_count_map, user_id)
    entry_count_map[user_id] = {}
    SurvivorEntry::GAME_TYPE_ARRAY.each { |game_type|
      entry_count_map[user_id][game_type] = [0,0]
    }
  end

  # GET /all_bets
  def all_bets
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end
    @current_year = current_season_year
  end

  # GET /ajax/survivor_entries/game/:game_type
  def ajaxshowall
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    @game_type = SurvivorEntry.name_to_game_type(params[:game_type])
    @entries_by_type = get_entries_by_type(@game_type)
    @entry_to_bets_map = get_bets_map_by_type(@game_type)
    render :layout => "ajax"
  end

  # GET /kill_entries
  def kill_entries
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end
    @current_year = current_season_year
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
    @current_year = current_season_year
    @current_week = current_week
    @selected_week = params[:number].to_i
    
    render "kill_entries"
  end 

  # GET /ajax/kill_entries/week/:number
  def ajax_kill_week
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    # only let user see weeks that have completed
    @week = Week.where({year: current_season_year, number: params[:number].to_i}).first
    if @week && DateTime.now > @week.start_time
      @entries_without_bets = get_entries_without_bets(@week.number)
    end
    render :layout => "ajax"
  end

  # DELETE /kill_entries/week/:number
  def kill_all
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

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

  # returns the entries which do not have the correct number of bets during the specified week,
  # which are currently alive, or were killed during the specified week.
  def get_entries_without_bets(week)
    entries = SurvivorEntry.includes(:user)
                           .joins(:user)
                           .where(year: current_season_year)
                           .where("is_alive = true OR knockout_week = " + week.to_s)
                           .order(:game_type, :user_id, :entry_number)

    week_bets = SurvivorBet.includes([:nfl_game, :nfl_team])
                           .joins(:survivor_entry)
                           .joins(:nfl_game)
                           .where(week: week)
                           .where(:survivor_entries => {year: current_season_year})
                           .order("survivor_entries.id, nfl_schedules.week")
    entry_id_to_bets_map = build_entry_id_to_bets_map(week_bets)

    entries_without_bets = []
    entries.each { |entry|
      if entry_missing_pick_in_week(entry, week, entry_id_to_bets_map)
        entries_without_bets << entry
      end
    }
    return entries_without_bets
  end
end
