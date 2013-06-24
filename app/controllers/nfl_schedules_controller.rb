class NflSchedulesController < ApplicationController
  # GET /nfl_schedules
  # GET /nfl_schedules.json
  def index
    # TODO show dates in user's time zone
    @nfl_schedules = NflSchedule.includes(:home_nfl_team)
                                .includes(:away_nfl_team)
                                .order(:week)
                                .order(:start_time)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @nfl_schedules }
    end
  end

  # GET /nfl_schedules/1
  # GET /nfl_schedules/1.json
  def show
    @nfl_schedule = NflSchedule.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @nfl_schedule }
    end
  end

  # GET /nfl_schedules/new
  # GET /nfl_schedules/new.json
  def new
    @nfl_schedule = NflSchedule.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @nfl_schedule }
    end
  end

  # GET /nfl_schedules/1/edit
  def edit
    @nfl_schedule = NflSchedule.find(params[:id])
  end

  # POST /nfl_schedules
  # POST /nfl_schedules.json
  def create
    @nfl_schedule = NflSchedule.new(params[:nfl_schedule])

    respond_to do |format|
      if @nfl_schedule.save
        format.html { redirect_to @nfl_schedule, notice: 'Nfl schedule was successfully created.' }
        format.json { render json: @nfl_schedule, status: :created, location: @nfl_schedule }
      else
        format.html { render action: "new" }
        format.json { render json: @nfl_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /nfl_schedules/1
  # PUT /nfl_schedules/1.json
  def update
    @nfl_schedule = NflSchedule.find(params[:id])

    respond_to do |format|
      if @nfl_schedule.update_attributes(params[:nfl_schedule])
        format.html { redirect_to @nfl_schedule, notice: 'Nfl schedule was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @nfl_schedule.errors, status: :unprocessable_entity }
      end
    end
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
