module SurvivorEntriesHelper

  TABLE_CLASS = 'table table-striped table-bordered table-condensed center dashboardtable
                 vertmiddle'
  TABLE_DASH_CLASS = 'table table-dash-striped table-bordered table-condensed center dashboardtable
                 vertmiddle'

  # Displays the currently selected entries for the specified game_type, as well as allows the user
  # to update the number of selected entries, if the season has not yet begun.
  def entries_selector(game_type, type_to_entry_map, span_size, before_season)
    entries_html = "<div class='span" + span_size.to_s + " survivorspan center'>
                      <h4>" + SurvivorEntry.game_type_title(game_type) + "</h4>"
    
    # Show existing entries
    current_entries = type_to_entry_map[game_type]
    if !current_entries.nil?
      entries_html << "<div class='row-fluid'>"
      span_size = get_span_size(current_entries.size, SurvivorEntry::MAX_ENTRIES_MAP[game_type])
      offset_size = get_offset_size(current_entries.size, span_size)

      entry_count = 0
      current_entries.each do |current_entry|
        entry_count += 1
        entries_html << "<div class='survivorspan span" + span_size.to_s
        if (offset_size > 0)
          entries_html << " offset" + offset_size.to_s
          offset_size = 0
        end
        entries_html << "'><h5>" +
                             link_to(SurvivorEntry.game_type_abbreviation(game_type) + " #" + 
                                         current_entry.entry_number.to_s,
                                     "/survivor_entries/" + current_entry.id.to_s,
                                     class: 'btn-link-black') +
                          "</h5>"

        # TODO Allow user to change picks in bulk

        entries_html << "</div>"
      end
      entries_html << "</div>"
    else
      entry_count = 0
    end
    
    # If season has not begun, allow user to update count of entries
    if before_season
      entries_html << "<p><strong>Entry count:</strong>
                          <select name='game_" + game_type.to_s + "' class='input-mini'>"
      0.upto(SurvivorEntry::MAX_ENTRIES_MAP[game_type]) { |num_games|
        entries_html << "   <option value=" + num_games.to_s
        if num_games == entry_count
          entries_html << " selected"
        end
        entries_html << ">" + num_games.to_s + "</option>"
      }
      entries_html << "   </select>
                       </p>"
    end
    entries_html << "</div>"
    return entries_html.html_safe
  end

  # Displays all bets for all entries for a specific game type
  def entries_bet_display(game_type, type_to_entry_map, entry_to_bets_map, span_size)
    entries_html = "<div class='span" + span_size.to_s + " center survivorspan'>
                      <h4>" + SurvivorEntry.game_type_title(game_type) + "</h4>"
    
    # Show all bets, separated by entries
    current_entries = type_to_entry_map[game_type]
    if !current_entries.nil?
      entries_html << "<div class='row-fluid'>"
      span_size = get_span_size(current_entries.size, SurvivorEntry::MAX_ENTRIES_MAP[game_type])
      offset_size = get_offset_size(current_entries.size, span_size)

      entry_count = 0
      current_entries.each do |current_entry|
        entry_count += 1
        entries_html << "<div class='survivorspan span" + span_size.to_s
        if (offset_size > 0)
          entries_html << " offset" + offset_size.to_s
          offset_size = 0
        end
        if !current_entry.is_alive
          entries_html << " dead"
        end
        entries_html << "'><h5>" +
                             link_to(SurvivorEntry.game_type_abbreviation(game_type) + " #" + 
                                         current_entry.entry_number.to_s,
                                     "/survivor_entries/" + current_entry.id.to_s,
                                     class: 'btn-link-black') +
                          "</h5>"

        # Show all bets for the entry
        entries_html << "<table class='" + TABLE_DASH_CLASS + "'>
                           <thead><tr>
                             <th>Week</th>
                             <th>Team</th>
                           </tr></thead>"
        if entry_to_bets_map.has_key?(current_entry.id)
          entry_to_bets_map[current_entry.id].each { |bet|
            entries_html << "<tr"
            if !bet.is_correct.nil?
              entries_html << " class='" + (bet.is_correct ? "green-row" : "red-row") + "'"
            elsif !current_entry.is_alive
              entries_html << " class='dead-row'"
            end
            entries_html <<     ">
                               <td>" + bet.nfl_game.week.to_s + "</td>
                               <td>" + bet.nfl_team.abbreviation + "</td>
                             </tr>"
          }
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
  def entry_bets_table(game_type_name, selector_to_bet_map, week_team_to_game_map, nfl_teams_map)
    entry_html = "<table class='" + TABLE_CLASS + "'>
                    <thead><tr>
                      <th>Week</th>
                      <th>Selected Team</th>
                      <th>Opponent</th>
                      <th>Result</th>
                    </tr></thead>"

    # TODO if entry is dead, show read-only
    game_type = SurvivorEntry.name_to_game_type(game_type_name)
    selected_team_ids = selector_to_bet_map.values.map { |bet| bet.nfl_team_id }

    1.upto(SurvivorEntry::MAX_WEEKS_MAP[game_type]) { |week|
      1.upto(SurvivorEntry.bets_in_week(game_type, week)) { |bet_number|
        # TODO if selected game has already started, lock it.
        entry_html << "<tr>
                        <td>" + week.to_s + "</td>
                        <td class='tdselect'>
                          <select name='" + SurvivorBet.bet_selector(week, bet_number) + "'>
                            <option value=0></option>"
        existing_bet = selector_to_bet_map[SurvivorBet.bet_selector(week, bet_number)]
        nfl_teams_map.values.each { |nfl_team|
      	  # Only allow team to be selected if it has a game during that week, and it has not already
      	  # been selected in a different week.
      	  team_game = week_team_to_game_map[NflSchedule.game_selector(week, nfl_team.id)]
      	  if !team_game.nil?
      	  	is_selected_team = !existing_bet.nil? && (existing_bet.nfl_team_id == nfl_team.id)
      	  	if is_selected_team || !selected_team_ids.include?(nfl_team.id)
              entry_html << "<option "
            
              # show bet is selected if bet already exists
              if is_selected_team
                entry_html << "selected "
              end

              # dropdown shows name of NFL team
              entry_html << "value=" + nfl_team.id.to_s + ">" +
                            nfl_team.full_name + "</option>"
            end
          end
        }
        entry_html <<      "</select></td>
                        <td>"
        # If bet already exists for this week, show opponent
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
        # TODO if bet already exists and game is complete, show result
        entry_html <<      "</td>
                      </tr>"
      }
    }

    entry_html << "</table>"
    return entry_html.html_safe
  end

  # shows the table of all bets for all users, for the specified game type
  def all_bets_table(game_type, entries_by_type, entry_to_bets_map, logged_in_user)
    bets_html = "<table class='" + TABLE_CLASS + "'>
                   <thead>
                     <tr>
                       <th rowspan='2'>Entry</th>
                       <th colspan='" + SurvivorEntry::MAX_BETS_MAP[game_type].to_s + "'>Weeks</th>
                     </tr>
                     <tr>"
    1.upto(SurvivorEntry::MAX_WEEKS_MAP[game_type]) { |week|
      bets_html << "<th colspan='" + SurvivorEntry.bets_in_week(game_type, week).to_s + "'>" +
                   week.to_s + "</th>"
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
                      <td class='"
      # if entry is dead, cross out entry name
      if !entry.is_alive
        bets_html << "dead-cell red-cell"
      end

      bets_html << "'>" + entry.user.full_name + " " + entry.entry_number.to_s + "</td>"
      bets = entry_to_bets_map[entry.id]
      1.upto(SurvivorEntry::MAX_WEEKS_MAP[game_type]) { |week|
        1.upto(SurvivorEntry.bets_in_week(game_type, week)) { |bet_number|
          # Show selected team, marking correct/incorrect, if game is complete.
          bets_html << "<td"
          if !bets.nil?
            bet = bets[SurvivorBet.bet_selector(week, bet_number)]
            if !bet.nil?
              if !bet.is_correct.nil?
                bets_html << " class='" + (bet.is_correct ? "green-cell" : "red-cell").to_s + "'"  
              elsif !entry.is_alive
                bets_html << " class='dead-cell'"
              end
              bets_html << ">" + bet.nfl_team.abbreviation
            else
              bets_html << ">"
            end
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
