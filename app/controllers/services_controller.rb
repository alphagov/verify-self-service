class ServicesController < ApplicationController
  include ControllerConcern
  include ComponentConcern

  before_action :check_authorisation

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

private

  def check_authorisation
    authorize ServicesController
  rescue Pundit::NotAuthorizedError
    flash[:warn] = t('shared.errors.authorisation')
    redirect_to root_path
  end

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
