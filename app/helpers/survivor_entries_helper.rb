module SurvivorEntriesHelper

  # Displays the currently selected entries for the specified game_type, as well as allows the user
  # to update the number of selected entries, if the season has not yet begun.
  def entries_selector(game_type, type_to_entry_map, before_season)
    entries_html = ""
    if before_season
      # show existing entries
      current_entries = type_to_entry_map[game_type]
      if !current_entries.nil?
      	entries_html << "<div class='row-fluid'>"
        span_size = 12 / SurvivorEntry::MAX_ENTRIES_MAP[game_type]
        entry_count = 0
        current_entries.each do |current_entry|
          entry_count += 1
          entries_html << "<div class='span" + span_size.to_s + "'>" +
                             "<h5>" + game_type.to_s + " " + entry_count.to_s + "</h5>" + 
                          "</div>"
        end
        entries_html << "</div>"
      else
      	entry_count = 0
      end

      # Allow user to update count of entries
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
    return entries_html.html_safe
  end

  # returns the number of entries allowed to be created for the specified survivor entry game type
  def entries_remaining(game_type, type_to_entry_map)
    num_entries = type_to_entry_map.has_key?(game_type) ? type_to_entry_map[game_type].length : 0
    return SurvivorEntry::MAX_ENTRIES_MAP[game_type] - num_entries
  end
end
