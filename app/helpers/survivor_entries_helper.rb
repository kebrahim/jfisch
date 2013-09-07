module SurvivorEntriesHelper

  # Displays the currently selected entries for the specified game_type, as well as allows the user
  # to update the number of selected entries, if the season has not yet begun.
  def entries_selector(game_type, type_to_entry_map, span_size, before_season)
    entries_html = "<div class='span" + span_size.to_s + " bigentryspan center'>
                      <h4>" + link_to(SurvivorEntry.game_type_title(game_type),
                      	              "/" + game_type.to_s,
                      	              class: 'btn-link-black') + "</h4>"
    current_entries = type_to_entry_map[game_type]
    entry_count = current_entries ? current_entries.size : 0

    # If season has not begun, allow user to update count of entries
    if before_season
      entries_html << "<strong>Entry count:</strong>
                          <select name='game_" + game_type.to_s + "' class='input-mini'>"
      
      if @admin_function
        max_entries = SurvivorEntry::ADMIN_MAX_ENTRIES_MAP[game_type]
      else
        max_entries = [SurvivorEntry::MAX_ENTRIES_MAP[game_type], entry_count].max
      end

      0.upto(max_entries) { |num_games|
        entries_html << "   <option value=" + num_games.to_s
        if num_games == entry_count
          entries_html << " selected"
        end
        entries_html << ">" + num_games.to_s + "</option>"
      }
      entries_html << "   </select>"
    end

    # Show existing entries
    if !current_entries.nil?
      entries_html << "<div class='row-fluid'>"
      span_size = get_span_size(current_entries.size, SurvivorEntry::MAX_ENTRIES_MAP[game_type])
      offset_size = get_offset_size(current_entries.size, span_size)

      entry_count = 0
      current_entries.each do |current_entry|
        entry_count += 1
        if (entry_count > 1 && ((entry_count % SurvivorEntry::MAX_ENTRIES_MAP[game_type]) == 1))
          entries_html << "</div><div class='row-fluid'>"
        end

        entries_html << "<div class='entriesspan span" + span_size.to_s
        if (offset_size > 0)
          entries_html << " offset" + offset_size.to_s
          offset_size = 0
        end
        entries_html << "'><h5>"
        if current_entry.is_alive
          entries_html << link_to(SurvivorEntry.game_type_abbreviation(game_type) + " #" + 
                                      current_entry.entry_number.to_s,
                                  "/survivor_entries/" + current_entry.id.to_s,
                                  class: 'btn-link-black')
        else
          entries_html << SurvivorEntry.game_type_abbreviation(game_type) + " #" + 
                                      current_entry.entry_number.to_s
        end
        entries_html << "</h5>"

        # Allow user to change picks in bulk
        entries_html << mini_entry_bets_table(current_entry)

        entries_html << "</div>"
      end
      entries_html << "</div>"
    end
    
    entries_html << "</div>"
    return entries_html.html_safe
  end

  # returns the miniature version of the entry_bets_table, which only includes week number and
  # selected team
  def mini_entry_bets_table(survivor_entry)
    bet_html = "<table class='" + ApplicationHelper::TABLE_STRIPED_CLASS + " table-dashboard'>
                    <thead><tr>
                      <th>Wk</th>
                      <th>Team</th>
                    </tr></thead>"
    game_type = survivor_entry.get_game_type
    1.upto(SurvivorEntry::MAX_WEEKS_MAP[game_type]) { |week|
      1.upto(SurvivorEntry.bets_in_week(game_type, week)) { |bet_number|
        existing_bet = @selector_to_bet_map[SurvivorBet.bet_entry_selector(
            survivor_entry.id, week, bet_number)]
        
        if survivor_entry.is_alive || (week <= survivor_entry.knockout_week) || existing_bet
          bet_html << "<tr"
          if !existing_bet.nil?
            if !existing_bet.is_correct.nil? &&
                (survivor_entry.is_alive || existing_bet.week <= survivor_entry.knockout_week)
              bet_html << " class='" + (existing_bet.is_correct ? "green-row" : "red-row") + "'"
            elsif !survivor_entry.is_alive
              bet_html << " class='dead-row'"
            end
          elsif !survivor_entry.is_alive
            if survivor_entry.knockout_week == week
              bet_html << " class='red-row'"
            else
              bet_html << " class='dead-row'"
            end
          end

          # week number
          bet_html << "><td>" + week.to_s + "</td>"

          # if pick is locked for this week [game has already started or week start time has already
          # passed], show as read-only
          pick_locked = false
          if (DateTime.now > @week_to_start_time_map[week]) ||
             (!existing_bet.nil? && (DateTime.now > existing_bet.nfl_game.start_time))
            pick_locked = true
          end

          # If bet exists & game is complete, show result; otherwise, show dropdown with available
          # teams
          if !existing_bet.nil? && 
              (!existing_bet.is_correct.nil? || !survivor_entry.is_alive || pick_locked)
            bet_html << "<td>" + existing_bet.nfl_team.abbreviation + "</td>"
          elsif !survivor_entry.is_alive || pick_locked
            if !survivor_entry.is_alive && survivor_entry.knockout_week == week
              bet_html << "<td>--</td>"
            else
              bet_html << "<td></td>"
            end
          else
            bet_html << get_mini_team_select(week, bet_number, survivor_entry, existing_bet)
          end
          bet_html << "</tr>"
        end
      }
    }
    bet_html << "</table>"
    return bet_html
  end

  def get_mini_team_select(week, bet_number, survivor_entry, existing_bet)
    select_html = "<td class='tdselect'>
                     <select class='input-entries' name='" +
                         SurvivorBet.bet_entry_selector(survivor_entry.id, week, bet_number) + "'>
                     <option value=0></option>"

    # collect selected team ids for the given entry
    selected_team_ids = get_selected_team_ids(survivor_entry)
    @nfl_teams_map.values.each { |nfl_team|
      # Only allow team to be selected if it has a game during that week, which hasn't yet started,
      # and it has not already been selected in a different week within the same entry.
      team_game = @week_team_to_game_map[NflSchedule.game_selector(week, nfl_team.id)]
      if !team_game.nil? && DateTime.now < team_game.start_time
        is_selected_team = !existing_bet.nil? && (existing_bet.nfl_team_id == nfl_team.id)
        if is_selected_team || !selected_team_ids.include?(nfl_team.id)
          select_html << "<option "
            
          # show bet is selected if bet already exists
          if is_selected_team
            select_html << "selected "
          end

          # dropdown shows name of NFL team
          select_html << "value=" + nfl_team.id.to_s + ">" + nfl_team.abbreviation + "</option>"
        end
      end
    }
    select_html << "</select></td>"
    return select_html
  end
  
  # returns the selected nfl team ids for all bets for a particular user, which are associated with
  # the specified entry
  def get_selected_team_ids(survivor_entry)
    selected_team_ids = []
    @selector_to_bet_map.values.each { |bet|
      if bet.survivor_entry_id == survivor_entry.id
        selected_team_ids << bet.nfl_team_id
      end
    }
    return selected_team_ids
  end

  # displays the buttons at the bottom of the my_entries page
  def entries_buttons
  	buttons_html = "<p class='center'>"

    if @admin_function
      buttons_html << "<a href='/users/" + @user.id.to_s + "/dashboard' class='btn btn-success'>
                         Back to Dashboard
                       </a>&nbsp&nbsp"
    end
    
    # Show update bets button if user has entries
    if !@type_to_entry_map.values.empty?
      buttons_html << "<button class='btn btn-primary' name='updatebets'>Make Picks</button>
                      &nbsp"
    end

    # Show update entries button if season has not yet begun
    if @before_season
      buttons_html <<
          "<button class='btn btn-inverse' name='updateentries'>Update Entry Counts</button>
           &nbsp"
    end

    # Always show cancel button
    buttons_html << "<button class='btn' name='cancel'>Cancel</button></p>"
    return buttons_html.html_safe
  end

  # Displays all bets for all entries for a specific game type
  def entries_bet_display(game_type, type_to_entry_map, entry_to_bets_map, span_size)
    entries_html = "<div class='span" + span_size.to_s + " center'>
                      <h4>" + link_to(SurvivorEntry.game_type_title(game_type),
                      	              "/" + game_type.to_s,
                      	              class: 'btn-link-black') +
                     "</h4>"
    
    # Show all bets, separated by entries
    current_entries = type_to_entry_map[game_type]
    if !current_entries.nil?
      span_size = get_span_size(current_entries.size, SurvivorEntry::MAX_ENTRIES_MAP[game_type])
      offset_size = get_offset_size(current_entries.size, span_size)

      entry_count = 0
      entries_html << "<div class='row-fluid'>"
      current_entries.each do |current_entry|
        entry_count += 1
        if (entry_count > 1 && ((entry_count % SurvivorEntry::MAX_ENTRIES_MAP[game_type]) == 1))
          entries_html << "</div><div class='row-fluid'>"
        end

        entries_html << "<div class='survivorspan span" + span_size.to_s
        if (offset_size > 0)
          entries_html << " offset" + offset_size.to_s
          offset_size = 0
        end
        
        if !current_entry.is_alive
          # if entry is dead, highlight entry in red
          entries_html << " dead"
        elsif entry_missing_pick_in_week(current_entry, @current_week.number)
          # if entry is missing a pick for current week, highlight entry in yellow
          entries_html << " missing"
        end

        entries_html << "'><h5>"
        if current_entry.is_alive
          entries_html << link_to(SurvivorEntry.game_type_abbreviation(game_type) + " #" + 
                                         current_entry.entry_number.to_s,
                                     "/survivor_entries/" + current_entry.id.to_s,
                                     class: 'btn-link-black')
        else
          entries_html << SurvivorEntry.game_type_abbreviation(game_type) + " #" + 
                                         current_entry.entry_number.to_s
        end
        entries_html << "</h5>"

        # Show all bets for the entry
        entries_html <<
            "<table class='" + ApplicationHelper::TABLE_STRIPED_CLASS + " table-dashboard'>
               <thead><tr>
                 <th>Wk</th>
                 <th>Team</th>
               </tr></thead>"

        has_knockout_bet = current_entry.is_alive
        if entry_to_bets_map.has_key?(current_entry.id)
          entry_to_bets_map[current_entry.id].each { |bet|
            entries_html << "<tr"
            if !bet.is_correct.nil? &&
                (current_entry.is_alive || bet.week <= current_entry.knockout_week)
              entries_html << " class='" + (bet.is_correct ? "green-row" : "red-row") + "'"
            elsif !current_entry.is_alive
              entries_html << " class='dead-row'"
            end
            entries_html <<     ">
                               <td>" + bet.nfl_game.week.to_s + "</td>
                               <td"
            if !bet.is_correct.nil?
              entries_html << " title='" + bet.game_result + "'"
            end
            entries_html <<       ">" + bet.nfl_team.abbreviation + "</td>
                             </tr>"

            if !has_knockout_bet && bet.week == current_entry.knockout_week
              has_knockout_bet = true
            end
          }
        end
        if !has_knockout_bet
          entries_html << "<tr class='red-row'>
                             <td>" + current_entry.knockout_week.to_s + "</td>
                             <td>--</td>
                           </tr>"
        end
        entries_html << "</table></div>"
      end
      entries_html << "</div>"
    else
      entry_count = 0
    end

    entries_html << "</div>"
    return entries_html.html_safe
  end

  # returns the size of the span elements based on the number of existing entries and the max number
  # allowed
  def get_span_size(num_entries, max_entries)
    if max_entries == 2
      return 6
    elsif max_entries == 4
      return (num_entries < 4) ? 4 : 3
    end
  end

  # returns the size of the initial offset number of existing entries and the span size
  def get_offset_size(num_entries, span_size)
    if span_size == 3
      return 0
    elsif span_size == 4
      return (num_entries == 1) ? 4 : ((num_entries == 2) ? 2 : 0)
    elsif span_size == 6
      return (num_entries == 1) ? 3 : 0
    end
  end

  # returns the number of entries allowed to be created for the specified survivor entry game type
  def entries_remaining(game_type, type_to_entry_map)
    num_entries = type_to_entry_map.has_key?(game_type) ? type_to_entry_map[game_type].length : 0
    return SurvivorEntry::MAX_ENTRIES_MAP[game_type] - num_entries
  end

  # shows the table of the specified array of bets, allowing the user to change only those which
  # haven't been locked yet.
  def entry_bets_table(survivor_entry, selector_to_bet_map, week_team_to_game_map, nfl_teams_map,
  	                   week_to_start_time_map)
    entry_html = "<table class='" + ApplicationHelper::TABLE_STRIPED_CLASS + "'>
                    <thead><tr>
                      <th>Week</th>
                      <th>Selected Team</th>
                      <th>Opponent</th>
                      <th>Result</th>
                    </tr></thead>"

    game_type = survivor_entry.get_game_type
    1.upto(SurvivorEntry::MAX_WEEKS_MAP[game_type]) { |week|
      1.upto(SurvivorEntry.bets_in_week(game_type, week)) { |bet_number|
        entry_html << "<tr"
        existing_bet = selector_to_bet_map[SurvivorBet.bet_selector(week, bet_number)]
        if !existing_bet.nil?
          if !existing_bet.is_correct.nil? &&
              (survivor_entry.is_alive || existing_bet.week <= survivor_entry.knockout_week)
            entry_html << " class='" + (existing_bet.is_correct ? "green-row" : "red-row") + "'"
          elsif !survivor_entry.is_alive
            entry_html << " class='dead-row'"
          end
        elsif !survivor_entry.is_alive
          if survivor_entry.knockout_week == week
            entry_html << " class='red-row dead-row'"
          else
            entry_html << " class='dead-row'"
          end
        end
        entry_html << ">
                        <td>" + week.to_s + "</td>"
        
        # if pick is locked for this week [game has already started or week start time has already
        # passed], show as read-only
        pick_locked = false
        if (DateTime.now > week_to_start_time_map[week]) ||
           (!existing_bet.nil? && (DateTime.now > existing_bet.nfl_game.start_time))
          pick_locked = true
        end

        # If bet exists & game is complete, show result; otherwise, show dropdown with available
        # teams
        if !existing_bet.nil? && 
            (!existing_bet.is_correct.nil? || !survivor_entry.is_alive || pick_locked)
          entry_html << "<td>" + existing_bet.nfl_team.full_name + "</td>"
        elsif !survivor_entry.is_alive || pick_locked
          if !survivor_entry.is_alive && survivor_entry.knockout_week == week
            entry_html << "<td>--</td>"
          else
            entry_html << "<td></td>"
          end
        else
          entry_html << get_team_select(week, bet_number, existing_bet, nfl_teams_map,
        	                            week_team_to_game_map, selector_to_bet_map)
        end

        # If bet already exists, show opponent
        entry_html <<  "<td>"
        if !existing_bet.nil?
          game = week_team_to_game_map[NflSchedule.game_selector(week, existing_bet.nfl_team_id)]
          if !game.nil?
          	opponent_team_id = game.opponent_team_id(existing_bet.nfl_team_id)
          	opponent_team = nfl_teams_map[opponent_team_id]
            entry_html << game.matchup_string(opponent_team)
          end
        end
        entry_html <<      "</td>
                        <td>"
        
        # If bet already exists and game is complete, show result
        if !existing_bet.nil? && !existing_bet.is_correct.nil?
          entry_html << existing_bet.game_result
        end

        entry_html <<      "</td>
                      </tr>"
      }
    }

    entry_html << "</table>"
    return entry_html.html_safe
  end

  # returns the select tag with all of the available nfl teams to select from, marking the team
  # from the specified existing bet as selected, if it exists
  def get_team_select(week, bet_number, existing_bet, nfl_teams_map, week_team_to_game_map, 
  	                  selector_to_bet_map)
    select_html = "<td class='tdselect'>
                     <select name='" + SurvivorBet.bet_selector(week, bet_number) + "'>
                     <option value=0></option>"
    selected_team_ids = selector_to_bet_map.values.map { |bet| bet.nfl_team_id }                  
    nfl_teams_map.values.each { |nfl_team|
      # Only allow team to be selected if it has a game during that week, which hasn't yet started,
      # and it has not already been selected in a different week.
      team_game = week_team_to_game_map[NflSchedule.game_selector(week, nfl_team.id)]
      if !team_game.nil? && DateTime.now < team_game.start_time
        is_selected_team = !existing_bet.nil? && (existing_bet.nfl_team_id == nfl_team.id)
      	if is_selected_team || !selected_team_ids.include?(nfl_team.id)
          select_html << "<option "
            
          # show bet is selected if bet already exists
          if is_selected_team
            select_html << "selected "
          end

          # dropdown shows name of NFL team
          select_html << "value=" + nfl_team.id.to_s + ">" + nfl_team.full_name + "</option>"
        end
      end
    }
    select_html << "</select></td>"
    return select_html
  end

  # displays the update picks buttons if the specified entry is still alive
  def display_update_picks_buttons(survivor_entry)
    button_html = ""
    if survivor_entry.is_alive
      button_html <<
        "<p class='center'>
          <button class='btn btn-primary' name='save'>Update Picks</button>
          <button class='btn' name='cancel'>Cancel</button>
        </p>"
    end
    return button_html.html_safe
  end

  # shows the table of all bets for all users, for the specified game type
  def all_bets_table(game_type, entries_by_type, entry_to_bets_map, logged_in_user, current_week,
                     game_week)
    bets_html = "<table class='" + ApplicationHelper::TABLE_CLASS + " smallfonttable'>
                   <thead>
                     <tr>
                       <th rowspan='2'>Entry</th>"
    
    max_week = [current_week, game_week].max
    if max_week > 0
      bets_html << "<th class='leftborderme' colspan='" +
          SurvivorEntry::MAX_BETS_MAP[game_type].to_s + "'>Weeks</th>"
    end
    bets_html <<    "</tr>
                     <tr>"
    # Show bets for all weeks up to the current week.
    1.upto(max_week) { |week|
      bets_html << "<th class='leftborderme' colspan='" +
          SurvivorEntry.bets_in_week(game_type, week).to_s + "'>" + week.to_s + "</th>"
    }
    bets_html <<    "</tr>
                   </thead>"

    entries_by_type.each { |entry|
      bets_html << "<tr class='"

      # highlight logged-in user's entries
      if entry.user_id == logged_in_user.id
        bets_html << "my-row"
      end
      bets_html <<            "'>
                      <td class='rightborderme "
      # if entry is dead, cross out entry name
      if !entry.is_alive
        bets_html << "dead-cell red-cell"
      end

      bets_html << "'>"
      if entry.user_id == logged_in_user.id
      	bets_html << link_to((entry.user.full_name + " " + entry.entry_number.to_s),
      	        "/survivor_entries/" + entry.id.to_s)
      else
      	bets_html << entry.user.full_name + " " + entry.entry_number.to_s
      end
      bets_html << "</td>"
      bets = entry_to_bets_map[entry.id]
      1.upto(max_week) { |week|
        1.upto(SurvivorEntry.bets_in_week(game_type, week)) { |bet_number|
          # Show selected team, marking correct/incorrect, if game is complete.
          bets_html << "<td"
          if !bets.nil?
            bet = bets[SurvivorBet.bet_selector(week, bet_number)]
            if !bet.nil?
              if entry.is_alive || week <= entry.knockout_week
                if !bet.is_correct.nil?
                  bets_html << " class='" + (bet.is_correct ? "green-cell" : "red-cell").to_s + "'
                                 title='" + bet.game_result + "'"
                end
                bets_html << ">"

                # only show bet if it's marked as correct/incorrect, the game has already started,
                # or the game's week lock has already occurred
                if !bet.is_correct.nil? || (DateTime.now > bet.nfl_game.start_time) ||
                    (bet.week <= current_week)
                  bets_html << bet.nfl_team.abbreviation
                end
              else
                bets_html << ">"
              end
            elsif entry.knockout_week == week
              # no bets were made during week & entry was knocked out
              bets_html << " class='red-cell'>--"
            else
              bets_html << ">"
            end
          elsif entry.knockout_week == week
            # no bets were made, but entry was knocked out in week 1
            bets_html << " class='red-cell'>--"
          else
            bets_html << ">"
          end
          bets_html << "</td>"
        }
      }
      bets_html << "</tr>"
    }

    bets_html << "</table>"
    return bets_html.html_safe
  end

  # returns a table of stats for the specified game_type, including the total alive, eliminated
  # and remaining entries in each week.
  def entry_stats_table(game_type, week_to_entry_stats_map, current_week)
    stats_html = "<h4>Entry Stats</h4>
                 <table class='" + ApplicationHelper::TABLE_CLASS + " smallfonttable'>
                   <thead>
                     <tr>
                       <th rowspan=2>Stat</th>"
    if current_week > 0
      stats_html << "<th class='leftborderme' colspan='" +
          SurvivorEntry::MAX_BETS_MAP[game_type].to_s + "'>Weeks</th>"
    end
    stats_html <<   "</tr><tr>"
    1.upto(current_week) { |week|
      stats_html << "<th class='leftborderme'>" + week.to_s + "</th>"
    }
    stats_html <<   "</thead>"

    stats_html << "<tr><td class='rightborderme'>Total Entries</td>"
    1.upto(current_week) { |week|
      stats_html << "<td>" + week_to_entry_stats_map[week]["alive"].to_s + "</td>"
    }
    
    stats_html << "</tr>
                   <tr><td class='rightborderme'>Eliminated Entries</td>"
    1.upto(current_week) { |week|
      stats_html << "<td>" + week_to_entry_stats_map[week]["elim"].to_s + "</td>"
    }

    stats_html << "</tr>
                   <tr><td class='rightborderme'>Remaining Entries</td>"
    1.upto(current_week) { |week|
      stats_html << "<td>" + (week_to_entry_stats_map[week]["alive"] -
                              week_to_entry_stats_map[week]["elim"]).to_s + "</td>"
    }

    stats_html << "</tr></table>"
    return stats_html.html_safe
  end

  # displays the all entries table, including number of entries for all the specified users
  def all_entries_table(users, user_to_entries_count_map)
    all_entries_html = "<table class='" + ApplicationHelper::TABLE_CLASS + "'>
                          <thead><tr>
                            <th rowspan=2 colspan=2 class='rightborderme'>User</th>
                            <th colspan=2 class='rightborderme'>Survivor</th>
                            <th colspan=2 class='rightborderme'>Anti-Survivor</th>
                            <th colspan=2>High-Roller</th>
                          </tr>
                          <tr>
                            <th class='rightborderme'>Total</th><th class='rightborderme'>Alive</th>
                            <th class='rightborderme'>Total</th><th class='rightborderme'>Alive</th>
                            <th class='rightborderme'>Total</th><th>Alive</th>
                          </tr></thead>"
    
    # number of (total & alive) entries per user
    users.each { |user|
      all_entries_html <<
          "<tr><td>" + link_to(user.full_name, '/users/' + user.id.to_s + "/entries") + "</td>
               <td>" + user.email + "</td>"
      if user_to_entries_count_map.has_key?(user.id)
        [:survivor, :anti_survivor, :high_roller].each { |game_type|
          0.upto(1) { |idx|
            all_entries_html << "<td"
            all_entries_html << " class='leftborderme'" if idx == 0
            all_entries_html << ">" + user_to_entries_count_map[user.id][game_type][idx].to_s +
                                "</td>"
          }
        }
      else
        0.upto(5) { |idx|
          all_entries_html << "<td"
          all_entries_html << " class='leftborderme'" if idx.even?
          all_entries_html << ">0</td>"
        }
      end
      all_entries_html << "</tr>"
    }

    # total entries for all users
    all_entries_html << "<tr class='bold-row'><td class='topborderme' colspan=2>Totals</td>"
    [:survivor, :anti_survivor, :high_roller].each { |game_type|
      0.upto(1) { |idx|
        all_entries_html << "<td class='topborderme"
        all_entries_html << " leftborderme" if idx.even?
        all_entries_html << "'>" + user_to_entries_count_map[0][game_type][idx].to_s + "</td>"
      }
    }

    all_entries_html << "</tr></table>"
    return all_entries_html.html_safe
  end

  # returns a table of the specified entries, indicating username, game type & whether the entry is
  # alive
  def kill_entries_table(entries_without_bets)
    kill_html = "<table class='" + ApplicationHelper::TABLE_CLASS + "'>
                    <thead><tr>
                      <th>Entry</th>
                      <th>Game Type</th>
                      <th>Status</th>
                    </tr></thead>"
    entries_without_bets.each { |entry|
      kill_html << "<tr>
                      <td>" + link_to(entry.user.full_name + " " + entry.entry_number.to_s,
                                      "/users/" + entry.user_id.to_s + "/dashboard") + "</td>
                      <td>" + entry.type_title + "</td>
                      <td>" + (entry.is_alive ? "Alive" : "Dead") + "</td>
                    </tr>"
    }
    kill_html << "</table>"
    return kill_html.html_safe
  end

  # returns true if the user is missing a bet for any of their entries, during the specified week
  def entries_missing_picks_for_week(week_number)
    @type_to_entry_map.values.flatten.each { |entry|
      if entry.is_alive && entry_missing_pick_in_week(entry, week_number)
        return true
      end
    }
    return false
  end

  # returns true if the specified entry is missing a pick during the specified week_number
  def entry_missing_pick_in_week(entry, week_number)
    num_picks = 0
    if @entry_to_bets_map.has_key?(entry.id)
      @entry_to_bets_map[entry.id].each { |bet|
        if bet.week == week_number
          num_picks += 1
        end
      }
    end
    return num_picks < entry.number_bets_required(week_number)
  end

  # displays table of all bets for all users, for the admin to view
  def all_user_bets_table
    bets_html = "<table class='" + ApplicationHelper::TABLE_CLASS + " smallfonttable'>
                   <thead>
                     <tr>
                       <th rowspan='2'>Entry</th>
                       <th class='leftborderme' colspan='" +
                           SurvivorEntry::MAX_BETS_MAP[@game_type].to_s + "'>Weeks</th>
                     </tr>
                     <tr>"
 
    # Show bets for all weeks up to the current week.
    1.upto(SurvivorEntry::MAX_WEEKS_MAP[@game_type]) { |week|
      bets_html << "<th class='leftborderme' colspan='" +
          SurvivorEntry.bets_in_week(@game_type, week).to_s + "'>" + week.to_s + "</th>"
    }
    bets_html <<    "</tr>
                   </thead>"

    @entries_by_type.each { |entry|
      bets_html << "<tr>
                      <td class='rightborderme "

      # if entry is dead, cross out entry name
      if !entry.is_alive
        bets_html << "red-cell"
      end
      bets_html << "'>" + link_to(entry.user.full_name + " " + entry.entry_number.to_s,
          "/survivor_entries/" + entry.id.to_s) + "</td>"

      bets = @entry_to_bets_map[entry.id]
      1.upto(SurvivorEntry::MAX_WEEKS_MAP[@game_type]) { |week|
        1.upto(SurvivorEntry.bets_in_week(@game_type, week)) { |bet_number|
          bets_html << "<td"
          if !bets.nil?
            bet = bets[SurvivorBet.bet_selector(week, bet_number)]
            if !bet.nil?
              if !bet.is_correct.nil?
                bets_html << " class='" + (bet.is_correct ? "green-cell" : "red-cell").to_s + "'
                               title='" + bet.game_result + "'"
              end
              bets_html << ">" + bet.nfl_team.abbreviation
            elsif entry.knockout_week == week
              # no bets were made during week & entry was knocked out
              bets_html << " class='red-cell'>--"
            else
              bets_html << ">"
            end
          elsif entry.knockout_week == week
            # no bets were made, but entry was knocked out in week 1
            bets_html << " class='red-cell'>--"
          else
            bets_html << ">"
          end
          bets_html << "</td>"
        }
      }
      bets_html << "</tr>"
    }

    bets_html << "</table>"
    return bets_html.html_safe
  end
end
