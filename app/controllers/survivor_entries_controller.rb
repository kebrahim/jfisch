class SurvivorEntriesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /my_entries
  def my_entries
    @user = current_user
    if !@user.nil?
      # TODO before_season depends on start of season [9/5]
      @before_season = true

      current_year = Date.today.year
      @type_to_entry_map = build_type_to_entry_map(
          SurvivorEntry.where({user_id: @user.id, year: current_year}))
    else
      redirect_to root_url
    end
  end

  # Returns a hash of survivor entry game type to an array of the entries of that type
  def build_type_to_entry_map(entries)
    type_to_entry_map = {}
    entries.each do |entry|
      if type_to_entry_map.has_key?(entry.game_type)
        type_to_entry_map[entry.game_type] << entry
      else
        type_to_entry_map[entry.game_type] = [entry]
      end
    end
    return type_to_entry_map
  end

  # POST /my_entries
  def save_entries
    # TODO create/delete entries

    # re-direct user to my_entries page
    redirect_to my_entries_url
  end

  # GET /survivor_entries
  # GET /survivor_entries.json
  def index
    @survivor_entries = SurvivorEntry.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @survivor_entries }
    end
  end

  # GET /survivor_entries/1
  # GET /survivor_entries/1.json
  def show
    @survivor_entry = SurvivorEntry.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @survivor_entry }
    end
  end

  # GET /survivor_entries/new
  # GET /survivor_entries/new.json
  def new
    @survivor_entry = SurvivorEntry.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @survivor_entry }
    end
  end

  # GET /survivor_entries/1/edit
  def edit
    @survivor_entry = SurvivorEntry.find(params[:id])
  end

  # POST /survivor_entries
  # POST /survivor_entries.json
  def create
    @survivor_entry = SurvivorEntry.new(params[:survivor_entry])

    respond_to do |format|
      if @survivor_entry.save
        format.html { redirect_to @survivor_entry, notice: 'Survivor entry was successfully created.' }
        format.json { render json: @survivor_entry, status: :created, location: @survivor_entry }
      else
        format.html { render action: "new" }
        format.json { render json: @survivor_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /survivor_entries/1
  # PUT /survivor_entries/1.json
  def update
    @survivor_entry = SurvivorEntry.find(params[:id])

    respond_to do |format|
      if @survivor_entry.update_attributes(params[:survivor_entry])
        format.html { redirect_to @survivor_entry, notice: 'Survivor entry was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @survivor_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /survivor_entries/1
  # DELETE /survivor_entries/1.json
  def destroy
    @survivor_entry = SurvivorEntry.find(params[:id])
    @survivor_entry.destroy

    respond_to do |format|
      format.html { redirect_to survivor_entries_url }
      format.json { head :no_content }
    end
  end
end
