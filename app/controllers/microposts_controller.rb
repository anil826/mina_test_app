class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  before_action :correct_user, only: :destroy

  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.save
      flash[:success] = "Micropost created!"
      redirect_to root_url
    else
      @feed_items = []
      render 'sample/home'
    end
  end

  def correct_user
    @micropost = current_user.microposts.where(id: params[:id]).take
    redirect_to root_url if @micropost.nil?
  end
  def destroy
    @micropost.destroy
    flash[:danger] = "Micropost Deleted"
    redirect_to root_url
  end
  private
  def micropost_params
    params.require(:micropost).permit(:content, :picture)
  end
end
