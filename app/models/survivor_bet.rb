class SurvivorBet < ActiveRecord::Base
  belongs_to :survivor_entry
  belongs_to :nfl_game, :class_name => 'NflSchedule', :foreign_key => "nfl_game_id"
  belongs_to :nfl_team
  attr_accessible :is_correct, :week, :bet_number

  # returns the name of the select param for selecting a team to bet on
  def self.bet_selector(week, bet_number)
    return "bet_" + week.to_s + "_" + bet_number.to_s
  end

  # returns the name of the select param for selecting a team to bet on, for this bet
  def selector(week, bet_number)
    return SurvivorBet.bet_selector(self.week, self.bet_number)
  end
end
