class MsaComponentsController < ApplicationController
  before_action :find_teams, only: %i[edit]

  def index
    @msa_components = MsaComponent.all
  end

  def new
    @component = NewMsaComponentEvent.new
    @hub_environments_legacy = Rails.configuration.hub_environments_legacy.keys
    @teams = Team.all
  end

  def edit
    @component = MsaComponent.find(params[:id])
    @hub_environments_legacy = Rails.configuration.hub_environments_legacy.keys
    @teams = Team.all
  end

  def show
    @component = MsaComponent.find_by_id(params[:id])
    @available_services = Service.msa_available
  end

  def create
    @component = NewMsaComponentEvent.create(component_params)
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
    @component = MsaComponent.find_by_id(params[:id])
    @component.assign_attributes(component_params)
    @event = ChangeComponentEvent.create(component: @component)

    if @event.valid?
      redirect_to msa_components_path
    else
      Rails.logger.info(@event.errors.full_messages)
      @teams = Team.all
      @hub_environments_legacy = Rails.configuration.hub_environments_legacy.keys

      render :edit
    end
  end

  def destroy
    component = MsaComponent.find_by_id(params[:id])
    if component.present?
      DeleteComponentEvent.create(component: component, data: { component_id: component.id, component_name: component.name, component_type: component.type })
    end
    redirect_to admin_path(anchor: component&.component_type)
  end

  def associate_service
    is_component_present = MsaComponent.exists?(params[:msa_component_id])
    service = Service.find_by_id(params[:service_id])

    if is_component_present && service.present?
      @event = AssignMsaComponentToServiceEvent.create(service: service, msa_component_id: params[:msa_component_id])

      if @event.valid?
        redirect_to msa_component_path(params[:msa_component_id])
      else
        Rails.logger.info(@event.errors.full_messages)

        render :show
      end
    else
      flash[:error] = I18n.t('service.errors.unknown_component_or_service') unless is_component_present && service.present?
      redirect_to admin_path(anchor: 'MsaComponent')
    end
  end

private

  def component_params
    params.require(:component).permit(:name, :entity_id, :team_id, :environment)
  end

  def find_teams
    @teams = Team.all
  end
end
