class UsersController < ApplicationController
  helper_method :sort_column, :sort_direction

  # GET /users
  # GET /users.json
  def index
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end
  
    # if sort column is a name column, also add other name
    column = sort_column
    order_columns = [wrap_column_if_string(column)]
    if column.ends_with?("name")
      order_columns << wrap_column_if_string(
          column == :first_name.to_s ? :last_name.to_s : :first_name.to_s)
    end

    @users = User.order(get_order_by_string(order_columns, sort_direction))

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # wraps the specified column in a "lower()" if it's a string column
  def wrap_column_if_string(column)
    return User::SORTABLE_STRING_COLUMNS.include?(column) ?
       "lower(" + column + ")" : column
  end

  # returns the order_by string for users, using the specified columns and direction
  def get_order_by_string(order_columns, direction)
    order_by_string = ''
    first_column = true
    order_columns.each { |column|
      if first_column
        first_column = false
      else
        order_by_string += ", "
      end
      order_by_string += column + ' ' + direction
    }
    return order_by_string
  end

  # GET /users/new
  # GET /users/new.json
  def new
    logout_user
    @current_user = current_user
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
    @user.is_blacklisted = false

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
          # send confirmation email
          @user.send_confirmation
          redirect_to root_url,
              notice: 'User was successfully created; please check your email to confirm account creation!'
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

  # GET /confirm/:confirmation_code
  def confirm
    logout_user
    @user = User.find_by_confirmation_token(params[:confirmation_code])
    notice_message = ""
    if @user
      @user.update_attributes({ is_confirmed: true, confirmation_token: nil })
      notice_message = "Successfully confirmed account; please login!"
    else
      notice_message = "Error: Invalid confirmation URL; token does not exist"
    end
    redirect_to root_url, notice: notice_message
  end

  # GET /users/:id/confirm
  def confirm_user
    @current_user = current_user
    if @current_user.nil? || !@current_user.is_admin
      redirect_to root_url
      return
    end

    user = User.find(params[:id])
    if user && !user.is_confirmed
      user.update_attributes({ is_confirmed: true, confirmation_token: nil })
      confirmation_message = "Successfully confirmed user's account!"
    else
      confirmation_message = "Error: Invalid user for confirmation"
    end
    redirect_to users_url, notice: confirmation_message
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

  private
  def sort_column
    User::SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : :first_name.to_s
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
