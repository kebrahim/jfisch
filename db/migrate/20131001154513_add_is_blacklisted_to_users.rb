class AddIsBlacklistedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_blacklisted, :boolean, :default => false, :null => false
  end
end
