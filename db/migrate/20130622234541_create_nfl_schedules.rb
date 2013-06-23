class CreateNflSchedules < ActiveRecord::Migration
  def change
    create_table :nfl_schedules do |t|
      t.integer :year
      t.integer :week
      t.belongs_to :home_nfl_team, :class_name => 'NflTeam', :foreign_key => "home_nfl_team_id"
      t.belongs_to :away_nfl_team, :class_name => 'NflTeam', :foreign_key => "away_nfl_team_id"
      t.datetime :start_time
      t.integer :home_score
      t.integer :away_score

      t.timestamps
    end
    add_index :nfl_schedules, :home_nfl_team_id
    add_index :nfl_schedules, :away_nfl_team_id
    add_index :nfl_schedules, [:year, :week, :home_nfl_team_id, :away_nfl_team_id],
        {:unique => true, :name => "nfl_schedule_year_week_teams_uq"}
  end
end
