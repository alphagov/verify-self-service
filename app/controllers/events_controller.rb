class EventsController < ApplicationController
  include UserInfo
  def index
    @user_list = UserInfo.all_users
    @page_number = params[:page] || 1
    @events = Event
      .page(@page_number)
    render :index
  end
end
