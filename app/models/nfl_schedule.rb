class NflSchedule < ActiveRecord::Base
  belongs_to :home_nfl_team, :class_name => 'NflTeam', :foreign_key => "home_nfl_team_id"
  belongs_to :away_nfl_team, :class_name => 'NflTeam', :foreign_key => "away_nfl_team_id"
  attr_accessible :away_score, :home_score, :start_time, :week, :year

  # returns the name of the select param for selecting a specific game where a particular team plays
  # during a particular week
  def self.game_selector(week, team_id)
  	return week.to_s + "-" + team_id.to_s
  end

  # returns the name of the select param for this game's home team
  def home_selector
  	return NflSchedule.game_selector(self.week, self.home_nfl_team_id)
  end

  # returns the name of the select param for this game's away team
  def away_selector
  	return NflSchedule.game_selector(self.week, self.away_nfl_team_id)
  end

  # returns the opponent team id in this matchup, assuming the specified team id is in the matchup
  def opponent_team_id(team_id)
    if team_id == self.home_nfl_team_id
      return self.away_nfl_team_id
    elsif team_id == self.away_nfl_team_id
      return self.home_nfl_team_id
    else
      return nil
    end
  end

  # returns the matchup string for the specified team, indicating whether the team is home or away
  def matchup_string(team)
    if team.id == self.away_nfl_team_id
      return "v. " + team.full_name
    elsif team.id == self.home_nfl_team_id
      return "@ " + team.full_name
    else
      return nil
    end
  end

  # returns the id of the nfl team that won this matchup, or nil if the score is tied or the score
  # hasn't been set yet.
  def winning_nfl_team_id
    if self.home_score > self.away_score
      return home_nfl_team_id
    elsif self.away_score > self.home_score
      return away_nfl_team_id
    else
      return nil
    end
  end

  # returns the id of the nfl team that lost this matchup, or nil if the score is tied or the score
  # hasn't been set yet.
  def losing_nfl_team_id
    if self.home_score < self.away_score
      return home_nfl_team_id
    elsif self.away_score < self.home_score
      return away_nfl_team_id
    else
      return nil
    end
  end
end
