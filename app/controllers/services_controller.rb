class ServicesController < ApplicationController
  include ControllerConcern
  include ComponentConcern

  def index
    component = component_by_klass_name(params)
    @services = component.services
  end

  def new
    @component = component_by_klass_name(params)
    @service_event = NewServiceEvent.new
  end

  def create
    @component = component_by_klass_name(params)
    @service_event = NewServiceEvent.create(service_params)

    if @service_event.valid? && @service_event.service.valid?
      redirect_to polymorphic_url(@component)
    else
      @service_event.errors.merge!(@service_event.service.errors)
      Rails.logger.info(@service_event.errors.full_messages)
      render :new
    end
  end

  def destroy
    service = Service.find_by_id(params[:id])
    if service.present?
      DeleteServiceEvent.create(service: service, data: { name: service.name, entity_id: service.entity_id })
      flash[:success] = t('common.action_successful', name: service.name, action: :deleted)
    else
      flash[:error] = t('common.error_not_found', name: Service.model_name.human)
    end
    redirect_to admin_path(anchor: :services)
  end

private

  def component_by_klass_name(params)
    component_id = params[component_key(params)]
    component_name = component_name_from_params(params)
    klass_component(component_name).find_by_id(component_id)
  end

  def service_params
    key = component_key(params)
    params.require(:service)
          .permit(:name, :entity_id)
          .merge("#{key}": params[key])
  end
end
