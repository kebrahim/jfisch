module UsersHelper

  # returns the number of entries allowed to be created for the specified survivor entry game type
  def entries_remaining(game_type, type_to_entry_map)
    num_entries = type_to_entry_map.has_key?(game_type) ? type_to_entry_map[game_type].length : 0
    return SurvivorEntry::MAX_ENTRIES_MAP[game_type] - num_entries
  end
end
