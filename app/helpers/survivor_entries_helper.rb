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
        span_size = get_span_size(current_entries.size, SurvivorEntry::MAX_ENTRIES_MAP[game_type])
        offset_size = get_offset_size(current_entries.size, span_size)

        entry_count = 0
        current_entries.each do |current_entry|
          entry_count += 1
          entries_html << "<div class='span" + span_size.to_s
          if (offset_size > 0)
            entries_html << " offset" + offset_size.to_s
            offset_size = 0
          end
          entries_html << "'><h5>" + SurvivorEntry.game_type_abbreviation(game_type) + " " + 
                                      entry_count.to_s + "</h5>" + 
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
end
