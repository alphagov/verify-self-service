class EventsController < ApplicationController
  def index
    @events = Event.includes(:aggregate).order('created_at')
    render :index
  end
end
