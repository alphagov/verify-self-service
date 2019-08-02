class SpComponentsController < ApplicationController
  before_action :check_authorisation, only: %i(new create)

  def index
    @sp_components = SpComponent.all
  end

  def new
    @component = NewSpComponentEvent.new
  end

  def show
    @component = SpComponent.find(params[:id])
  end

  def create
    @component = NewSpComponentEvent.create(component_params)
    if @component.valid?
      redirect_to root_path
    else
      Rails.logger.info(@component.errors.full_messages)
      render :new
    end
  end

private

  def check_authorisation
    authorize NewSpComponentEvent
  rescue Pundit::NotAuthorizedError
    flash[:warn] = t('shared.errors.authorisation')
    redirect_to root_path
  end

  def component_params
    params.require(:component).permit(:name, :component_type)
  end
end
