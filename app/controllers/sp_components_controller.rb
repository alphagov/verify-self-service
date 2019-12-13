class SpComponentsController < ApplicationController
  before_action :find_teams, only: %i[edit]

  def index
    @sp_components = SpComponent.all
  end

  def new
    @component = NewSpComponentEvent.new
    @hub_environments_legacy = Rails.configuration.hub_environments_legacy.keys
    @teams = Team.all
  end

  def show
    @component = SpComponent.find(params[:id])
    @available_services = Service.sp_available
  end

  def edit
    @component = SpComponent.find(params[:id])
    @hub_environments_legacy = Rails.configuration.hub_environments_legacy.keys
    @teams = Team.all
  end

  def create
    @component = NewSpComponentEvent.create(component_params)
    @hub_environments_legacy = Rails.configuration.hub_environments_legacy.keys
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
      @hub_environments_legacy = Rails.configuration.hub_environments_legacy.keys

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

  def associate_service
    is_component_present = SpComponent.exists?(params[:sp_component_id])
    service = Service.find_by_id(params[:service_id])

    if is_component_present && service.present?
      @event = AssignSpComponentToServiceEvent.create(service: service, sp_component_id: params[:sp_component_id])

      if @event.valid?
        redirect_to sp_component_path(params[:sp_component_id])
      else
        Rails.logger.info(@event.errors.full_messages)

        render :show
      end
    else
      flash[:error] = I18n.t('service.errors.unknown_component_or_service') unless is_component_present && service.present?
      redirect_to admin_path(anchor: 'SpComponent')
    end
  end

private

  def component_params
    params.require(:component).permit(:name, :component_type, :team_id, :environment, :vsp)
  end

  def find_teams
    @teams = Team.all
  end
end
