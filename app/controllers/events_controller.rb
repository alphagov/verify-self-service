class EventsController < ApplicationController
  def index
    authorize Event
    @page_number = params[:page] || 1
    @events = Event
              .page(@page_number)
    render :index
  rescue Pundit::NotAuthorizedError
    flash[:warn] = t('shared.errors.authorisation')
    redirect_to root_path
  end
end
