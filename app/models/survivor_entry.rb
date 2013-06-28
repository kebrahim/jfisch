class SurvivorEntry < ActiveRecord::Base
  extend Enumerize

  belongs_to :user
  attr_accessible :game_type, :is_alive, :used_autopick, :year

  enumerize :game_type, in: [:survivor, :anti_survivor, :high_roller, :second_chance]

  MAX_ENTRIES_MAP = { survivor: 4, anti_survivor: 2, high_roller: 2 }
end
