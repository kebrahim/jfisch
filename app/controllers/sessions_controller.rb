class SessionsController < ApplicationController
  def new
  	if cookies[:auth_token]
      user = User.find_by_auth_token(cookies[:auth_token])
    end
    if !user.nil?
      redirect_to dashboard_url
    end
  end

  def create
    user = User.authenticate(params[:email], params[:password])
    if user
      if params[:remember_me]
        cookies.permanent[:auth_token] = user.auth_token
      else
        cookies[:auth_token] = user.auth_token  
      end
      redirect_to dashboard_url
    else
      redirect_to root_url, notice: "Error: Invalid email or password"
    end
  end

  def destroy
    cookies.delete(:auth_token)
    redirect_to root_url
  end
end
