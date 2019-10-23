class SpComponentsController < ApplicationController
  before_action :find_teams, only: %i[edit]

  def index
    @sp_components = SpComponent.all
  end

  def new
    @component = NewSpComponentEvent.new
    @hub_environments = Rails.configuration.hub_environments.keys
    @teams = Team.all
  end

  def show
    @component = SpComponent.find(params[:id])
  end

  def edit
    @component = SpComponent.find(params[:id])
    @hub_environments = Rails.configuration.hub_environments.keys
    @teams = Team.all
  end

  def create
    @component = NewSpComponentEvent.create(component_params)
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
    @component = SpComponent.find_by_id(params[:id])
    @component.assign_attributes(component_params)
    @event = ChangeComponentEvent.create(component: @component)

    if @event.valid?
      redirect_to sp_components_path
    else
      Rails.logger.info(@event.errors.full_messages)
      @teams = Team.all
      @hub_environments = Rails.configuration.hub_environments.keys

      render :edit
    end
  end

  def destroy
    component = SpComponent.find_by_id(params[:id])
    if component.present?
      DeleteComponentEvent.create(component: component, data: { component_id: component.id, component_name: component.name, component_type: component.type })
    end
    redirect_to admin_path(anchor: component&.component_type)
  end

private

  def component_params
    params.require(:component).permit(:name, :component_type, :team_id, :environment, :vsp)
  end

  def find_teams
    @teams = Team.all
  end
end
