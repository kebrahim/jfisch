class PasswordResetsController < ApplicationController
  def new
  end

  def create
    user = User.find_by_email(params[:email])
    if user
      # if user exists, send password reset email and show confirmation message
      user.send_password_reset
      redirect_to root_url,
          :notice => "Email sent with password reset instructions. Please check your email."
    else
      # if user does not exist, show error message
      redirect_to "/password_resets/new",
          :notice => "Error: Email address does not exist. Please try again."
    end
  end

  def edit
    @user = User.find_by_password_reset_token!(params[:id])
  end

  def update
    @user = User.find_by_password_reset_token!(params[:id])
    if @user.password_reset_sent_at < 2.hours.ago
      redirect_to new_password_reset_path, :alert => "Password reset has expired."
    elsif @user.update_attributes(params[:user])
      redirect_to root_url, :notice => "Password has been reset."
    else
      redirect_to "/password_resets/" + params[:id].to_s + "/edit",
                  :notice => "Error: Invalid password. Please try again."
    end
  end  
end
