class ServicesController < ApplicationController
  include ControllerConcern
  include ComponentConcern

  def index
    @services = Service.all
  end

  def new
    @service_event = NewServiceEvent.new
  end

  def create
    @service_event = NewServiceEvent.create(service_params)

    if @service_event.valid?
      redirect_to admin_path
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
    end
    redirect_to admin_path(anchor: :services)
  end

private

  def service_params
    params.require(:service)
          .permit(:name, :entity_id)
  end
end
