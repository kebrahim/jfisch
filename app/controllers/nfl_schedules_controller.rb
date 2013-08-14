class NflSchedulesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /nfl_schedules
  # GET /nfl_schedules.json
  def index
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    @nfl_games = NflSchedule.includes(:home_nfl_team)
                            .includes(:away_nfl_team)
                            .order(:week)
                            .order(:start_time)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @nfl_games }
    end
  end

  # GET /nfl_schedules/1
  # GET /nfl_schedules/1.json
  def show
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    @nfl_game = NflSchedule.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @nfl_game }
    end
  end

  # GET /nfl_schedules/1/edit
  def edit
    @nfl_schedule = NflSchedule.find(params[:id])
  end

  # POST /nfl_schedules/1
  def update
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    @nfl_game = NflSchedule.find(params[:id])
    if !params["save"].nil?
      if params["home_score"] != '' && params["away_score"] != ''
        confirmation_message = ""
        SurvivorBet.transaction do 
          begin
            if @nfl_game.update_attributes({ home_score: params["home_score"].to_i, 
                                             away_score: params["away_score"].to_i })
              
              # update win/loss on all bets in this game
              bets_on_game = SurvivorBet.includes([:nfl_game, :survivor_entry])
                                        .where(nfl_game_id: @nfl_game)
              bets_on_game.each { |bet|
                has_correct_bet = bet.has_correct_bet
                entry = bet.survivor_entry

                # Only update bet's correct status if it has changed values, and the current entry
                # is alive or this entry was knocked out during this week, and the score is being
                # corrected.
                if (bet.is_correct.nil? || (bet.is_correct != has_correct_bet)) &&
                   (entry.is_alive || (entry.knockout_week == bet.nfl_game.week))
                  bet.update_attribute(:is_correct, has_correct_bet)
      
                  # update entry's is_alive status, if it should change.
                  # TODO entry should not be set to alive if week requires 2 bets, both were
                  # initially incorrect and now one is being changed to correct.
                  if entry.is_alive != has_correct_bet
                    attributes_to_update = {}

                    # set is_alive status
                    attributes_to_update[:is_alive] = has_correct_bet
                    
                    # set knockout_week
                    attributes_to_update[:knockout_week] = has_correct_bet ? nil : bet.nfl_game.week

                    entry.update_attributes(attributes_to_update)
                  end
                end
              }
              confirmation_message = "Score was successfully updated!"
            else
              confirmation_message = "Error: Problem occurred while updating score"
            end   
          rescue Exception => e
            confirmation_message = "Error: Problem occurred while updating score"
          end
        end     
      else
        confirmation_message = "Error: Both scores are required"
      end
    end
    redirect_to "/nfl_schedule/" + @nfl_game.id.to_s, notice: confirmation_message
  end

  # DELETE /nfl_schedules/1
  # DELETE /nfl_schedules/1.json
  def destroy
    @nfl_schedule = NflSchedule.find(params[:id])
    @nfl_schedule.destroy

    respond_to do |format|
      format.html { redirect_to nfl_schedules_url }
      format.json { head :no_content }
    end
  end

  # GET /ajax/nfl_schedule/week/:number
  def ajaxweek
    @week = Week.where({year: Date.today.year, number: params[:number].to_i}).first
    @games = NflSchedule.includes([:home_nfl_team, :away_nfl_team])
                        .where({year: Date.today.year, week: @week.number})
                        .order(:start_time)
    render :layout => "ajax"
  end
end
