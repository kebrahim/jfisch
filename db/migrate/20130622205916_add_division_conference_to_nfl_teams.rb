class AddDivisionConferenceToNflTeams < ActiveRecord::Migration
  def change
    add_column :nfl_teams, :division, :string
    add_column :nfl_teams, :conference, :string
  end
end
