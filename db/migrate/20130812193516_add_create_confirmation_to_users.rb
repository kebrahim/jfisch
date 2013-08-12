class AddCreateConfirmationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :is_confirmed, :boolean, :default => false, :null => false
  end
end
