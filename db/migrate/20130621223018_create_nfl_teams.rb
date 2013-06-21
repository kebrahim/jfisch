class CreateNflTeams < ActiveRecord::Migration
  def change
    create_table :nfl_teams do |t|
      t.string :city
      t.string :name
      t.string :abbreviation

      t.timestamps
    end
  end
end
