class UsersController < ApplicationController
  # GET /survivor
  def dashboard
    @user = current_user
    if !@user.nil?
      # TODO set beforeSeason based on start of season [9/5?]
      @beforeSeason = true

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

  # GET /survivor
  def survivor
    @user = current_user
    if !@user.nil?
      # depending on date [before/after start of season, redirect to proper page]
    else
      redirect_to root_url
    end
  end

  # GET /users
  # GET /users.json
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # GET /profile
  def profile
    @user = current_user
    if @user.nil?
      redirect_to root_url
    end
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    if !params["commit"].nil?
      respond_to do |format|
        if @user.save
          format.html { redirect_to root_url, notice: 'User was successfully created.' }
          format.json { render json: @user, status: :created, location: @user }
        else
          format.html { render action: "new" }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to root_url
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])

    if !params["commit"].nil?
      respond_to do |format|
        if @user.update_attributes(params[:user])
          format.html { redirect_to '/profile', notice: 'User successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: 'profile' }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to '/profile'
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
end
