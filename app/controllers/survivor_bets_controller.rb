class SurvivorBetsController < ApplicationController
  # GET /survivor_bets
  # GET /survivor_bets.json
  def index
    @survivor_bets = SurvivorBet.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @survivor_bets }
    end
  end

  # GET /survivor_bets/1
  # GET /survivor_bets/1.json
  def show
    @survivor_bet = SurvivorBet.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @survivor_bet }
    end
  end

  # GET /survivor_bets/new
  # GET /survivor_bets/new.json
  def new
    @survivor_bet = SurvivorBet.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @survivor_bet }
    end
  end

  # GET /survivor_bets/1/edit
  def edit
    @survivor_bet = SurvivorBet.find(params[:id])
  end

  # POST /survivor_bets
  # POST /survivor_bets.json
  def create
    @survivor_bet = SurvivorBet.new(params[:survivor_bet])

    respond_to do |format|
      if @survivor_bet.save
        format.html { redirect_to @survivor_bet, notice: 'Survivor bet was successfully created.' }
        format.json { render json: @survivor_bet, status: :created, location: @survivor_bet }
      else
        format.html { render action: "new" }
        format.json { render json: @survivor_bet.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /survivor_bets/1
  # PUT /survivor_bets/1.json
  def update
    @survivor_bet = SurvivorBet.find(params[:id])

    respond_to do |format|
      if @survivor_bet.update_attributes(params[:survivor_bet])
        format.html { redirect_to @survivor_bet, notice: 'Survivor bet was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @survivor_bet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /survivor_bets/1
  # DELETE /survivor_bets/1.json
  def destroy
    @survivor_bet = SurvivorBet.find(params[:id])
    @survivor_bet.destroy

    respond_to do |format|
      format.html { redirect_to survivor_bets_url }
      format.json { head :no_content }
    end
  end
end
