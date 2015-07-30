class SessionsController < ApplicationController

  def new
    @user = User.all
  end

  def create
    user = User.where(email: params[:session][:email].downcase).take
    if user && user.authenticate(params[:session][:password])
      if user.activated?
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or user
      else
        message  = "Account not activated. "
        message += "Check your email for the activation link."
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash[:danger]= "Invalid / User Name and Password"
      render 'new'
    end
  end

  def destroy
   log_out if logged_in?
    redirect_to root_path
  end

end
