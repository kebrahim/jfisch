class SessionsController < ApplicationController
  def new
  	if session[:user_id]
      user = User.find(session[:user_id])
    end
    if !user.nil?
      redirect_to survivor_url
    end
  end

  def create
    user = User.authenticate(params[:email], params[:password])
    if user
      session[:user_id] = user.id
      redirect_to survivor_url
    else
      redirect_to root_url, notice: "Error: Invalid email or password"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url
  end
end
