class AddBetNumberToSurvivorBets < ActiveRecord::Migration
  def change
    add_column :survivor_bets, :bet_number, :integer
    add_index :survivor_bets, [:survivor_entry_id, :week, :bet_number],
              :name => "survivor_bets_entry_week_num_uq", :unique => true
  end
end
