class RulesController < ApplicationController
  def survivor
    handle_rules(:survivor)
  end

  def anti_survivor
    handle_rules(:anti_survivor)
  end

  def high_roller
    handle_rules(:high_roller)
  end

  def second_chance
    handle_rules(:second_chance)
  end

  def handle_rules(game_type)
    @user = current_user
    if @user.nil? || (game_type == :second_chance && @user.is_blacklisted)
      redirect_to root_url
      return
    end

    @game_type = game_type
    render "breakdown"
  end

  def sendgrid
  end
end
