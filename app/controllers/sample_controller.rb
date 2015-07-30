class SampleController < ApplicationController
  def home
    if logged_in?
    @micropost = current_user.microposts.build
    @feed_items = current_user.feeds.paginate(page: params[:page])
    end
  end

  def about
  end

  def destroy
  end
end
