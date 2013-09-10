class UserMailer < ActionMailer::Base
  default from: "noreply@fischmadness.com",
          bcc: "survivorbigbrother@gmail.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #

  # Sends an account confirmation email to the specified user
  def account_confirmation(user)
    @user = user
    mail :to => user.email, :subject => "Confirm Fisch Survivor Madness Account"
  end
  
  # Sends a password reset email to the specified user
  def password_reset(user)
    @user = user
    mail :to => user.email, :subject => "Fisch Survivor Madness Password Reset"
  end

  # Sends a survivor bet summary email to the specified user
  def survivor_bet_summary(user, bets_to_create, bets_to_update, week_team_to_game_map)
    @user = user
    @bets = bets_to_create
    @bets.push(*bets_to_update)
    @team_map = build_id_to_team_map(NflTeam.all)
    @week_team_to_game_map = week_team_to_game_map
    mail :to => user.email, :subject => "Fisch Survivor Madness Picks Summary"
  end

  # returns a map of nfl team id to team
  def build_id_to_team_map(teams)
    id_to_team_map = {}
    teams.each { |team|
      id_to_team_map[team.id] = team
    }
    return id_to_team_map
  end
end
