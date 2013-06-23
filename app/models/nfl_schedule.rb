class NflSchedule < ActiveRecord::Base
  belongs_to :home_nfl_team, :class_name => 'NflTeam', :foreign_key => "home_nfl_team_id"
  belongs_to :away_nfl_team, :class_name => 'NflTeam', :foreign_key => "away_nfl_team_id"
  attr_accessible :away_score, :home_score, :start_time, :week, :year
end
