namespace :importnfl do

  # environment is a rake task that loads all models
  desc "Imports NFL team data from CSV file"
  task :teams => :environment do
    require 'csv'
    teamcount = 0
    CSV.foreach(File.join(File.expand_path(::Rails.root), "/lib/assets/nfl_teams.csv")) do |row|
      city = row[0]
      name = row[1]
      abbreviation = row[2]
      conference = row[3]
      division = row[4]
      team = NflTeam.create(abbreviation: abbreviation, city: city, name: name,
                            conference: conference, division: division)
      teamcount += 1
    end
    puts "Imported " + teamcount.to_s + " NFL teams!"
  end
end