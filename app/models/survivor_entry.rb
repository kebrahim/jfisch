class SurvivorEntry < ActiveRecord::Base
  extend Enumerize

  belongs_to :user
  attr_accessible :game_type, :is_alive, :used_autopick, :year, :entry_number, :knockout_week

  enumerize :game_type, in: [:survivor, :anti_survivor, :high_roller, :second_chance]

  MAX_ENTRIES_MAP = { survivor: 4, anti_survivor: 2, high_roller: 2 }
  MAX_WEEKS_MAP = { survivor: 17, anti_survivor: 17, high_roller: 21 }
  MAX_BETS_MAP = { survivor: 22, anti_survivor: 22, high_roller: 21 }
  GAME_TYPE_ARRAY = [:survivor, :anti_survivor, :high_roller]
  TWO_GAME_WEEK_THRESHOLD = 13

  # Returns the game_type matching the specified name
  def self.name_to_game_type(game_type_name)
    if :survivor.to_s == game_type_name
      return :survivor
    elsif :anti_survivor.to_s == game_type_name
      return :anti_survivor
    elsif :high_roller.to_s == game_type_name
      return :high_roller
    else
      return nil
    end
  end

  # Returns the game_type matching this entry's game type name
  def get_game_type
    if :survivor.to_s == self.game_type
      return :survivor
    elsif :anti_survivor.to_s == self.game_type
      return :anti_survivor
    elsif :high_roller.to_s == self.game_type
      return :high_roller
    else
      return nil
    end
  end

  # Returns the abbreviation of the specified game type.
  def self.game_type_abbreviation(game_type)
    case game_type
    when :survivor
      return "Surv"
    when :anti_survivor
      return "Anti"
    when :high_roller
      return "HiRoll"
    else
      return nil
    end
  end

  # Returns the title of this entry's game type.
  def type_title
  	return SurvivorEntry.game_type_title(SurvivorEntry.name_to_game_type(self.game_type))
  end
 
  # Returns the title of the specified game type.
  def self.game_type_title(game_type)
    case game_type
    when :survivor
      return "Survivor"
    when :anti_survivor
      return "Anti-Survivor"
    when :high_roller
      return "High Roller"
    else
      return nil
    end
  end

  # returns the number of bets required for the specified game_type and week
  def self.bets_in_week(game_type, week)
    case game_type
    when :survivor
      return (week < TWO_GAME_WEEK_THRESHOLD) ? 1 : 2
    when :anti_survivor
      return (week < TWO_GAME_WEEK_THRESHOLD) ? 1 : 2
    when :high_roller
      return 1
    else
      return 0
    end
  end

  # returns the maximum number of weeks for this entry
  def max_weeks
    return SurvivorEntry::MAX_WEEKS_MAP[self.get_game_type]
  end
end
