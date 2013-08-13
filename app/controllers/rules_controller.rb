class RulesController < ApplicationController
  def survivor
  	@game_type = :survivor
    render "breakdown"
  end

  def anti_survivor
  	@game_type = :anti_survivor
    render "breakdown"
  end

  def high_roller
  	@game_type = :high_roller
    render "breakdown"
  end

  def sendgrid
  end
end
