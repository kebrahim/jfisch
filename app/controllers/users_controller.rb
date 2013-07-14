class UsersController < ApplicationController
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
  def create
    @user = User.new(params[:user])
    @user.role = :user

    if params["commit"]
      begin
        if User.find_by_names(@user.first_name, @user.last_name)
          redirect_to "/sign_up",
              notice: "Error: That first and last name is already taken. Please try again."
        elsif @user.save
          redirect_to root_url, notice: 'User was successfully created.'
        else
          render action: 'new'
        end
      rescue Exception => e
        redirect_to "/sign_up", notice: "Error: Unexpected error occurred: " + e.message
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
