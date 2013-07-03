module SurvivorEntriesHelper

  TABLE_CLASS = 'table table-striped table-bordered table-condensed center dashboardtable'

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
        entries_html << "'><h5>" +
                             link_to(SurvivorEntry.game_type_abbreviation(game_type) + " #" + 
                                         current_entry.entry_number.to_s,
                                     "/survivor_entries/" + current_entry.id.to_s,
                                     class: 'btn-link-black') +
                          "</h5>"

        # Show all bets for the entry
        entries_html << "<table class='" + TABLE_CLASS + "'>
                           <thead><tr>
                             <th>Week</th>
                             <th>Team</th>
                           </tr></thead>"
        if entry_to_bets_map.has_key?(current_entry.id)
          entry_to_bets_map[current_entry.id].each { |bet|
            entries_html << "<tr>
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
  def entry_bets_table(game_type_name, survivor_bets, team_to_games_map, nfl_teams)
    entry_html = "<table class='" + TABLE_CLASS + "'>
                    <thead><tr>
                      <th>Week</th>
                      <th>Selected Team</th>
                      <th>Opponent</th>
                      <th>Result</th>
                    </tr></thead>"

    # TODO if entry is dead, show read-only
    # TODO indicate where auto-pick was used
    game_type = SurvivorEntry.name_to_game_type(game_type_name)
    1.upto(SurvivorEntry::MAX_WEEKS_MAP[game_type]) { |week|
      1.upto(SurvivorEntry.bets_in_week(game_type, week)) { |bet_number|
        # TODO if bet already exists for this week, show selected bet, including opponent
        # TODO if bet already exists and game is complete, show result
        entry_html << "<tr>
                        <td>" + week.to_s + "</td>
                        <td class='tdselect'>
                          <select name='" + SurvivorBet.bet_selector(week, bet_number) + "'>
                            <option value=0></option>"
        nfl_teams.each { |nfl_team|
      	  # Only allow team to be selected if it has a game during that week.
      	  team_game = team_to_games_map[nfl_team.id][week]
      	  if !team_game.nil?
            # TODO if selected game has already started, lock it.
            entry_html << "<option value=" + nfl_team.id.to_s + ">" +
                          nfl_team.full_name + "</option>"
          end
        }
        entry_html <<      "</select></td>
                        <td></td>
                        <td></td>
                      </tr>"
      }
    }

    entry_html << "</table>"
    return entry_html.html_safe
  end
end
