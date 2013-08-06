namespace :importuser do

  # environment is a rake task that loads all models
  desc "Imports admin user data from CSV file"
  task :users => :environment do
    require 'csv'
    usercount = 0
    CSV.foreach(File.join(File.expand_path(::Rails.root), "/lib/assets/users.csv")) do |row|
      email = row[0]
      first_name = row[1]
      last_name = row[2]
      captain_code = row[3]
      is_super_admin = row[4]
      User.create(email: email, password: 'changeme', password_confirmation: 'changeme',
                  first_name: first_name, last_name: last_name, captain_code: captain_code,
                  role: (is_super_admin == 'true' ? :super_admin : :admin).to_s,
                  send_emails: false)
      usercount += 1
    end
    puts "Imported " + usercount.to_s + " Users!"
  end

  desc "Adds auth tokens to all existing users"
  task :auth => :environment do
    usercount = 0
    users = User.where(auth_token: nil)
    users.each { |user|
      user.generate_token(:auth_token)
      user.save
      usercount += 1
    }
    puts "Updated auth_token of " + usercount.to_s + " users!"
  end
end
