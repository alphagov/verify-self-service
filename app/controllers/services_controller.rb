class ServicesController < ApplicationController
  include ControllerConcern
  include ComponentConcern

  def index
    component = component_by_klass_name(params)
    @services = component.services
  end

  def new
    @component = component_by_klass_name(params)
    @service = NewServiceEvent.new
  end

  def create
    @component = component_by_klass_name(params)
    @service = NewServiceEvent.create(service_params)

    if @service.valid?
      redirect_to polymorphic_url(@component)
    else
      Rails.logger.info(@service.errors.full_messages)
      render :new
    end
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.info('Entity ID exists')
    render :new
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
