class EventsController < ApplicationController
  def index
    @page_number = params[:page] || 1
    @events = Event
              .page(@page_number)
    render :index
  end
end
