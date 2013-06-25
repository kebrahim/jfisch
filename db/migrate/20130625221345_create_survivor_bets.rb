class CreateSurvivorBets < ActiveRecord::Migration
  def change
    create_table :survivor_bets do |t|
      t.belongs_to :survivor_entry
      t.integer :week
      t.belongs_to :nfl_game
      t.belongs_to :nfl_team
      t.boolean :is_correct

      t.timestamps
    end
    add_index :survivor_bets, :survivor_entry_id
    add_index :survivor_bets, :nfl_game_id
    add_index :survivor_bets, :nfl_team_id
    add_index :survivor_bets, [:survivor_entry_id, :nfl_team_id],
        {:unique => true, :name => "survivor_bets_entry_team_uq"}
  end
end
