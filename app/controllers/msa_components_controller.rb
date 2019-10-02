class MsaComponentsController < ApplicationController
  before_action :find_teams, only: %i[edit]

  def index
    @msa_components = MsaComponent.all
  end

  def new
    @component = NewMsaComponentEvent.new
    @hub_environments = Rails.configuration.hub_environments.keys
    @teams = Team.all
  end

  def show
    @component = MsaComponent.find_by_id(params[:id])
  end

  def create
    @component = NewMsaComponentEvent.create(component_params)
    @hub_environments = Rails.configuration.hub_environments.keys
    if @component.valid?
      redirect_to admin_path
    else
      Rails.logger.info(@component.errors.full_messages)
      @teams = Team.all
      render :new
    end
  end

  def update
    msa_component = MsaComponent.find_by_id(params[:id])
    msa_component.team_id = params.dig(:component, :team_id)
    event = ChangeComponentEvent.create(
      component: msa_component,
    )
    unless event.valid?
      error_message = event.errors.full_messages
      flash[:notice] = error_message
    end
    redirect_to msa_components_path
  end

private

  def component_params
    params.require(:component).permit(:name, :entity_id, :team_id, :environment)
  end

  def find_teams
    @teams = Team.all
  end
end
