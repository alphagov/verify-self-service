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

  def edit
    @component = MsaComponent.find(params[:id])
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
    @component = MsaComponent.find_by_id(params[:id])
    @component.assign_attributes(component_params)
    @event = ChangeComponentEvent.create(component: @component)

    if @event.valid?
      redirect_to msa_components_path
    else
      Rails.logger.info(@event.errors.full_messages)
      @teams = Team.all
      @hub_environments = Rails.configuration.hub_environments.keys

      render :edit
    end
  end

  def delete
    component = MsaComponent.find_by_id(params[:id])
    change_event = DeleteComponentEvent.create(component: component, data: { component_id: component.id, component_name: component.name })
    flash[:error] = change_event.errors.full_messages.join(', ') unless change_event.errors.empty?
    redirect_to admin_path(anchor: 'MsaComponent')
  end

private

  def component_params
    params.require(:component).permit(:name, :entity_id, :team_id, :environment)
  end

  def find_teams
    @teams = Team.all
  end
end
