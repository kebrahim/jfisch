class SurvivorEntry < ActiveRecord::Base
  extend Enumerize

  belongs_to :user
  attr_accessible :game_type, :is_alive, :used_autopick, :year

  enumerize :game_type, in: [:survivor, :anti_survivor, :high_roller, :second_chance]

  MAX_ENTRIES_MAP = { survivor: 4, anti_survivor: 2, high_roller: 2 }

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

  # Returns the abbreviation of the specified game type.
  def self.game_type_abbreviation(game_type)
    case game_type
    when :survivor
      return "Surv"
    when :anti_survivor
      return "Anti"
    when :high_roller
      return "HiRo"
    else
      return nil
    end
  end
end
