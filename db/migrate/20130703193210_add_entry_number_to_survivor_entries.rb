class AddEntryNumberToSurvivorEntries < ActiveRecord::Migration
  def change
    add_column :survivor_entries, :entry_number, :integer
    add_index :survivor_entries, [:user_id, :year, :game_type, :entry_number],
              :name => "survivor_entries_user_year_type_num_uq", :unique => true
  end
end
