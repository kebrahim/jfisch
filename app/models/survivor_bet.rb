class SurvivorBet < ActiveRecord::Base
  belongs_to :survivor_entry
  belongs_to :nfl_game, :class_name => 'NflSchedule', :foreign_key => "nfl_game_id"
  belongs_to :nfl_team
  has_one :user, :through => :survivor_entry

  attr_accessible :is_correct, :week, :bet_number

  # returns the name of the select param for selecting a team to bet on
  # TODO remove these 2 methods
  def self.bet_selector(week, bet_number)
    return "bet_" + week.to_s + "_" + bet_number.to_s
  end

  # returns the name of the select param for selecting a team to bet on, for this bet
  def selector
    return SurvivorBet.bet_selector(self.week, self.bet_number)
  end

  # returns the name of the select param for selecting a team to bet on for a particular entry
  def self.bet_entry_selector(survivor_entry_id, week, bet_number)
    return "bet_" + survivor_entry_id.to_s + "_" + week.to_s + "_" + bet_number.to_s
  end

  # returns the name of the select param for selecting a team to bet on for a particular entry, for
  # this bet
  def entry_selector
    return SurvivorBet.bet_entry_selector(self.survivor_entry_id, self.week, self.bet_number)
  end

  # calculates whether this bet is correct based on the result of the associated game and the type
  # of this bet's entry.
  def has_correct_bet
    case self.survivor_entry.get_game_type
    when :survivor
      return self.nfl_team_id == self.nfl_game.winning_nfl_team_id
    when :anti_survivor
      return self.nfl_team_id == self.nfl_game.losing_nfl_team_id
    when :high_roller
      return self.nfl_team_id == self.nfl_game.winning_nfl_team_id
    when :second_chance
      return self.nfl_team_id == self.nfl_game.winning_nfl_team_id
    else
      return nil
    end
  end

  # returns the result of the game, according to the view of the selected team
  def game_result
    if self.is_correct.nil?
      return ""
    end
    return self.nfl_game.result(nfl_team_id) + " " + self.nfl_game.team_score(nfl_team_id).to_s + 
           "-" + self.nfl_game.opponent_score(nfl_team_id).to_s
  end
end
