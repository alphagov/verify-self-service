class SupportController < ApplicationController
  def index
    @support_email = Rails.configuration.support_email
    render :index
  end
end
