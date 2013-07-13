class AddKnockoutWeekToSurvivorEntries < ActiveRecord::Migration
  def change
    add_column :survivor_entries, :knockout_week, :integer
  end
end
