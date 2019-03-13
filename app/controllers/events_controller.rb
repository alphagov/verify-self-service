class EventsController < ApplicationController
  
  def index
    @page_number = params[:page] || 1
    @events = Event
      .includes(:aggregate)
      .order('id DESC')
      .page(@page_number)
    render :index
  end
end
