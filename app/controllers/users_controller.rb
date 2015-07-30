class UsersController < ApplicationController
  before_action :logged_in_user, only: [:edit, :update, :update, :destroy, :following, :followers ]
  before_action :correct_user, only: [:edit, :update ]
  before_action :admin_user, only: [:destroy]

  def index
    @users = User.all.paginate(page: params[:page])
  end

  def new
    @user = User.new
  end

  def show
    @user = User.where(id: params[:id]).take
    @microposts = @user.microposts.paginate(page: params[:page])
    logger.info "-------------------#{@user.inspect}"
  end

  def create
    @user = User.new(user_params)

    if @user.save
       @user.send_activation_email
       flash[:success] = "Plese check you email Account !"
     # log_in @user
      #flash[:success] = "Welcome to my Test Application"
      #redirect_to @user
      redirect_to root_url

    else
      render 'new'
    end
  end

  def edit
     @user = User.where(id: params[:id]).take
  end

  def update
    @user = User.where(id: params[:id]).take
    if @user.update_attributes(user_params)
      flash[:success] = "Update Successfull"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
   User.where(id: params[:id]).take.destroy
   flash[:success] = "User deleted"
   redirect_to users_url
  end

 private
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end


  def correct_user
    @user = User.where(id: params[:id]).take
    redirect_to root_url unless @user == current_user
  end

  def admin_user
    redirect_to(root_url) unless current_user.admin?
  end
  def following
    @title = "Following"
    @user  = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "Followers"
    @user  = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end

end
