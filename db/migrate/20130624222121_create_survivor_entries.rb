class CreateSurvivorEntries < ActiveRecord::Migration
  def change
    create_table :survivor_entries do |t|
      t.belongs_to :user
      t.integer :year
      t.string :game_type
      t.boolean :is_alive
      t.boolean :used_autopick

      t.timestamps
    end
    add_index :survivor_entries, :user_id
  end
end
