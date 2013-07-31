class AddSendEmailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :send_emails, :boolean, :default => false, :null => false
  end
end
