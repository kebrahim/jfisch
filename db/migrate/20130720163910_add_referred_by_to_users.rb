class AddReferredByToUsers < ActiveRecord::Migration
  def change
    add_column :users, :referred_by, :string
  end
end
