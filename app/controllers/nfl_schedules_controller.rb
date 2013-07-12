class NflSchedulesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /nfl_schedules
  # GET /nfl_schedules.json
  def index
    # TODO check admin user
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end

    # TODO show dates in user's time zone
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
    # TODO check admin user
    @user = current_user
    if @user.nil?
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
    # TODO check admin user
    @user = current_user
    if @user.nil?
      redirect_to root_url
      return
    end

    @nfl_game = NflSchedule.find(params[:id])
    if !params["save"].nil?
      if params["home_score"] != '' && params["away_score"] != ''
        # TODO wrap in transaction?
        if @nfl_game.update_attributes({ home_score: params["home_score"].to_i, 
                                         away_score: params["away_score"].to_i })
          
          # update win/loss on all bets in this game
          bets_on_game = SurvivorBet.includes([:nfl_game, :survivor_entry])
                                    .where(nfl_game_id: @nfl_game)
          bets_on_game.each { |bet|
            has_correct_bet = bet.has_correct_bet
            if bet.is_correct.nil? || (bet.is_correct != has_correct_bet)
              bet.update_attribute(:is_correct, has_correct_bet)
  
              # update entry's is_alive status if it should change.
              entry = bet.survivor_entry
              if entry.is_alive != has_correct_bet
                entry.update_attribute(:is_alive, has_correct_bet)

                # TODO if bet is incorrect, set knockout week on entry
              end
            end
          }
          confirmation_message = "Score was successfully updated!"
        else
          confirmation_message = "Error occurred while updating score"
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
end
