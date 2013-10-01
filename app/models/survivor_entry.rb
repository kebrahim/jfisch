class SurvivorEntry < ActiveRecord::Base
  extend Enumerize

  belongs_to :user
  has_many :survivor_bets, dependent: :destroy

  attr_accessible :game_type, :is_alive, :used_autopick, :year, :entry_number, :knockout_week

  enumerize :game_type, in: [:survivor, :anti_survivor, :high_roller, :second_chance]

  MAX_ENTRIES_MAP = { survivor: 4, anti_survivor: 2, high_roller: 2, second_chance: 4 }
  ADMIN_MAX_ENTRIES_MAP = { survivor: 8, anti_survivor: 4, high_roller: 4, second_chance: 8 }
  START_WEEK_MAP = { survivor: 1, anti_survivor: 1, high_roller: 1, second_chance: 7 }
  MAX_WEEKS_MAP = { survivor: 17, anti_survivor: 17, high_roller: 21, second_chance: 17 }
  MAX_BETS_MAP = { survivor: 22, anti_survivor: 21, high_roller: 21, second_chance: 22 }
  TWO_GAME_WEEK_THRESHOLD_MAP = { survivor: 13, anti_survivor: 14, high_roller: nil,
                                  second_chance: 7 }
  GAME_TYPE_ARRAY = [:survivor, :anti_survivor, :high_roller, :second_chance]

  # Returns the game_type matching the specified name
  def self.name_to_game_type(game_type_name)
    if :survivor.to_s == game_type_name
      return :survivor
    elsif :anti_survivor.to_s == game_type_name
      return :anti_survivor
    elsif :high_roller.to_s == game_type_name
      return :high_roller
    elsif :second_chance.to_s == game_type_name
      return :second_chance
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
    elsif :second_chance.to_s == self.game_type
      return :second_chance
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
    when :second_chance
      return "SecondChance"
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
      return "Regular Survivor"
    when :anti_survivor
      return "Anti-Survivor"
    when :high_roller
      return "High Roller"
    when :second_chance
      return "Second Chance"
    else
      return nil
    end
  end

  # returns the number of bets required for the specified game_type and week
  def self.bets_in_week(game_type, week)
    if week < SurvivorEntry::START_WEEK_MAP[game_type]
      return 0
    end
    two_week_threshold = SurvivorEntry::TWO_GAME_WEEK_THRESHOLD_MAP[game_type]
    if two_week_threshold
      return (week < two_week_threshold) ? 1 : 2
    end
    return 1
  end

  # returns the number of bets required for this entry, during the specified week
  def number_bets_required(week)
    return SurvivorEntry::bets_in_week(self.get_game_type, week)
  end

  # returns the maximum number of weeks for this entry
  def max_weeks
    return SurvivorEntry::MAX_WEEKS_MAP[self.get_game_type]
  end
end
