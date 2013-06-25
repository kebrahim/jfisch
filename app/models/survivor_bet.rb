class SurvivorBet < ActiveRecord::Base
  belongs_to :survivor_entry
  belongs_to :nfl_game, :class_name => 'NflSchedule', :foreign_key => "nfl_game_id"
  belongs_to :nfl_team
  attr_accessible :is_correct, :week
end
