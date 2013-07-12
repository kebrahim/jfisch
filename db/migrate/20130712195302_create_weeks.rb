class CreateWeeks < ActiveRecord::Migration
  def change
    create_table :weeks do |t|
      t.integer :year
      t.integer :number
      t.datetime :start_time

      t.timestamps
    end
    add_index :weeks, [:year, :number], {:unique => true, :name => "weeks_year_number_uq"}
    add_index :weeks, [:year, :start_time], {:unique => true, :name => "weeks_start_time_number_uq"}
  end
end
