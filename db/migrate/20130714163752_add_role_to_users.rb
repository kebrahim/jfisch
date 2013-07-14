class AddRoleToUsers < ActiveRecord::Migration
  def change
    add_column :users, :role, :string
    add_index :users, [:first_name, :last_name],
              :name => "users_first_last_name_uq", :unique => true
  end
end
