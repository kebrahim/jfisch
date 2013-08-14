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
                  send_emails: false, is_confirmed: true)
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

  desc "Adds default time zone to all existing users"
  task :timezone => :environment do
    usercount = 0
    users = User.where(time_zone: nil)
    users.each { |user|
      user.time_zone = "America/New_York"
      user.save
      usercount += 1
    }
    puts "Updated time zones of " + usercount.to_s + " users!"
  end

  desc "Confirms all existing users"
  task :confirm => :environment do
    usercount = 0
    users = User.where(is_confirmed: false)
    users.each { |user|
      user.is_confirmed = true
      user.save
      usercount += 1
    }
    puts "Confirmed " + usercount.to_s + " users!"
  end

  desc "Enables bet emails for all users"
  task :emails => :environment do
    usercount = 0
    users = User.where(send_emails: false)
    users.each { |user|
      user.send_emails = true
      user.save
      usercount += 1
    }
    puts "Enabled emailling for " + usercount.to_s + " users!"
  end
end
