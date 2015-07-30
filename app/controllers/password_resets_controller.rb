class PasswordResetsController < ApplicationController

   before_action :get_user, only: [:edit, :update]
   before_action :check_expiration, only: [:edit, :update]
  def new
  end
  
  def create
	@user = User.where(email: params[:password_reset][:email].downcase).take
  if @user
	  @user.create_reset_digest
	  @user.send_password_reset_email
	  flash[:info] = "Email send with password reset instructions"
          redirect_to root_url
       else
    flash.now[:danger] = "Email address not found"
    render 'new'
     end
  end

  def edit
  end

  def update
    if both_passwords_blank?
      flash.now[:danger] = "Password/confirmation can't be blank"
      render 'edit'
    elsif @user.update_attributes(user_params)
      log_in @user
      flash[:success] = "Password has been reset."
      redirect_to @user
    else
      render 'edit'
    end
  end

   # Returns true if password & confirmation are blank.
   def both_passwords_blank?
     params[:user][:password].blank? &&
     params[:user][:password_confirmation].blank?
   end

   def get_user
     @user = User.where(email: params[:email]).take
   end

   def check_expiration
     if @user.password_reset_expired?
       flash[:danger] = "This link is expired.. "
       redirect_to new_password_reset_url
     end
   end

private
  def user_params
    params.require(:user).permit(:password,:password_confirmation)
  end

end
