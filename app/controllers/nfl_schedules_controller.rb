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

    @weeks = Week.where(year: Date.today.year)
                 .order(:number)
    @current_week = game_week

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

  # GET /ajax/nfl_schedule/adminweek/:number
  def ajaxadminweek
    @week = Week.where({year: Date.today.year, number: params[:number].to_i}).first
    @games = NflSchedule.includes([:home_nfl_team, :away_nfl_team])
                        .where({year: Date.today.year, week: @week.number})
                        .order(:start_time, :id)
    render :layout => "ajax"
  end

  # GET /nfl_schedule/week/:number
  def show_week
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    @weeks = Week.where(year: Date.today.year)
                 .order(:number)
    @current_week = get_week_object_by_number(@weeks, params[:number].to_i).number
    
    render "index"
  end

  # POST /nfl_schedule/week/:number
  def update_week
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end
    
    @week = Week.where({year: Date.today.year, number: params[:number].to_i}).first
    confirmation_message = ""
    if params["updatescores"]
      nfl_games = NflSchedule.includes([:home_nfl_team, :away_nfl_team])
                             .where({year: Date.today.year, week: @week.number})
                             .order(:start_time)

      SurvivorBet.transaction do 
        begin
          error_messages = []
          nfl_games.each { |nfl_game|
            home_selector = nfl_game.id.to_s + "_home"
            away_selector = nfl_game.id.to_s + "_away"
     
            # if score changed for a specific game, update scores and save entire game; also, update
            # corresponding bets for game.
            home_score = params[home_selector] == '' ? nil : params[home_selector].to_i
            away_score = params[away_selector] == '' ? nil : params[away_selector].to_i
            if ((home_score != nfl_game.home_score) || (away_score != nfl_game.away_score))
              error_message = update_score_for_game(nfl_game, home_score, away_score)
              if !error_message.nil?
                error_messages << error_message
              end
            end
          }
          if error_messages.empty?
            confirmation_message = "Successfully updated scores!"
          else
            confirmation_message = "Error: " + error_messages.join('; ')
          end
        rescue Exception => e
          confirmation_message = "Error: Problem occurred while updating scores"
        end
      end
    end

    redirect_to "/nfl_schedule/week/" + params[:number], notice: confirmation_message
  end

  # Updates the scores of the specified game to the specified home & away scores, and also marks any
  # bets on that game either correct or incorrect, based on the updated score. If a bet is marked
  # incorrect, then the entry is killed if it's already alive.
  def update_score_for_game(nfl_game, home_score, away_score)
    if !home_score.nil? && !away_score.nil?
      error_message = nil
      if nfl_game.update_attributes({ home_score: home_score, 
                                      away_score: away_score })
        
        # update win/loss on all bets in this game
        bets_on_game = SurvivorBet.includes([:nfl_game, :survivor_entry])
                                  .where(nfl_game_id: nfl_game)
        bets_on_game.each { |bet|
          has_correct_bet = bet.has_correct_bet
          entry = bet.survivor_entry

          # Only update bet's correct status if the current entry is alive or this entry was knocked
          # out during this week, and the score is being corrected.
          if (entry.is_alive || (entry.knockout_week == bet.nfl_game.week))
            bet.update_attribute(:is_correct, has_correct_bet)

            # update entry's is_alive status, if it should change.
            entry_status = entry_status_for_bets_in_week(entry, bet.week)
            if entry.is_alive != entry_status
              attributes_to_update = {}

              # set is_alive status
              attributes_to_update[:is_alive] = entry_status
              
              # set knockout_week
              attributes_to_update[:knockout_week] = entry_status ? nil : bet.nfl_game.week

              entry.update_attributes(attributes_to_update)
            end
          end
        }
      else
        error_message = "Problem occurred while updating score"
      end   
    else
      error_message = "Both scores are required for " + nfl_game.matchup
    end
    return error_message
  end

  # determines what the 'is_alive' status of the specified entry should be, based on the bets made
  # during the specified week.
  def entry_status_for_bets_in_week(entry, week)
    # get bets for entry
    bets_for_entry = SurvivorBet.where({ survivor_entry_id: entry.id, week: week })
    
    # if this entry doesn't have enough bets, it should be killed [or remain killed], only if the
    # deadline for this week has occurred
    if bets_for_entry.count < entry.number_bets_required(week) &&
        week <= get_current_week_from_weeks(Week.where(year: Date.today.year).order(:number))
      return false
    end

    # an entry should only be killed if at least one of its bets are incorrect
    is_alive = true
    bets_for_entry.each { |bet|
      if !bet.is_correct.nil?
        is_alive &= bet.is_correct
      end
    }
    return is_alive
  end
end
