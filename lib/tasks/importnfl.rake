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

  desc "Imports NFL schedule data from CSV file"
  task :schedule => :environment do
    require 'csv'
    schedcount = 0
    year = Date.today.year
    CSV.foreach(File.join(File.expand_path(::Rails.root), "/lib/assets/nfl_schedule.csv")) do |row|
      # skip comment line
      if row[0].starts_with?("#")
        next
      end

      week = row[0].to_i
      home_team_abbr = row[1]
      away_team_abbr = row[2]
      game_date = row[3]
      game_time = row[4]

      # convert team_names to teams
      home_team = NflTeam.find_by_abbreviation(home_team_abbr)
      away_team = NflTeam.find_by_abbreviation(away_team_abbr)

      # convert game date/time to datetime
      start_time = DateTime.strptime(game_date + " " + game_time + " Atlantic Time (Canada)",
          "%m/%d/%Y %H:%M:%S %Z")

      # create schedule entry
      if (!home_team.nil? && !away_team.nil?)
        schedule = NflSchedule.new
        schedule.year = year
        schedule.week = week
        schedule.home_nfl_team_id = home_team.id
        schedule.home_score = nil
        schedule.away_nfl_team_id = away_team.id
        schedule.away_score = nil
        schedule.start_time = start_time
        if schedule.save
          schedcount += 1
        end
      else
        puts "found error with teams in row: " + row
      end
    end
    puts "Imported " + schedcount.to_s + " NFL schedule rows!"
  end
end