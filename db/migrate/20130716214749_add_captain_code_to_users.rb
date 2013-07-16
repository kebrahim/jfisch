class AddCaptainCodeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :captain_code, :string
  end
end
