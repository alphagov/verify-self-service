class SpComponentsController < ApplicationController
  before_action :check_authorisation, only: %i(new create)
  before_action :find_teams, only: %i[edit]
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

  def edit
    @sp_component = SpComponent.find_by_id(params[:id])
  end

  def update
    spcomponent = SpComponent.find_by_id(params[:id])
    spcomponent.team_id = params.dig(:component, :team_id)
    event = ChangeComponentEvent.create(
      component: spcomponent
    )
    unless event.valid?
      error_message = event.errors.full_messages
      flash[:notice] = error_message
    end
    redirect_to sp_components_path
  end

private

  def check_authorisation
    authorize NewSpComponentEvent
  rescue Pundit::NotAuthorizedError
    flash[:warn] = t('shared.errors.authorisation')
    redirect_to root_path
  end

  def component_params
    params.require(:component).permit(:name, :component_type, :team_id)
  end

  def find_teams
    @teams = Team.all
  end
end
