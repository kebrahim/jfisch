class UsersController < ApplicationController
  # GET /users
  # GET /users.json
  def index
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    @users = User.order("lower(last_name), lower(first_name)")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new
    @captain_code_feature = false
    @current_week = current_week
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    @admin_function = true
    @user = User.find(params[:id])
  end

  # GET /profile
  def profile
    @admin_function = false
    @current_user = current_user
    @user = @current_user
    if @user.nil?
      redirect_to root_url
    end
  end

  # POST /users
  def create
    @user = User.new(params[:user])

    # new user defaults to "user" role and receiving bet summary emails.
    @user.role = :user
    @user.send_emails = true
    
    # when captain code is supported, remove this hard-coded captain code & require user to enter it
    @user.captain_code = "blahblah"

    if params["commit"]
      begin
        if User.find_by_names(@user.first_name, @user.last_name)
          redirect_to "/sign_up",
              notice: "Error: First/last name is already taken. Please try again."
        elsif !User.uniq.pluck(:captain_code).include?(@user.captain_code)
          redirect_to "/sign_up",
              notice: "Error: Invalid captain code. Please try again."
        elsif @user.save
          redirect_to root_url, notice: 'User was successfully created.'
        else
          @current_week = current_week
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

    redirect_url = params.has_key?("admin_fxn") ? ('/users/' + @user.id.to_s + '/edit') : '/profile'

    if params["commit"]
      respond_to do |format|
        if @user.update_attributes(params[:user])
          format.html { redirect_to redirect_url, notice: 'User successfully updated.' }
          format.json { head :no_content }
        else
          format.html {
            if params.has_key?("admin_fxn")
              @admin_function = true
              @current_user = current_user
              render action: 'edit'
            else
              @admin_function = false
              @current_user = current_user
              render action: 'profile'
            end
          }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to redirect_url
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
