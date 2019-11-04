class ServicesController < ApplicationController
  include ControllerConcern
  include ComponentConcern

  def index
    @services = Service.all
  end

  def new
    @service = NewServiceEvent.new
  end

  def create
    service_event = NewServiceEvent.create(service_params)
    @service = service_event.service
    if @service.valid? && service_event.errors.empty?
      flash[:success] = t('common.action_successful', name: @service.name, action: :created)
      redirect_to admin_path(anchor: 'services')
    else
      @service.errors.merge!(service_event.errors)
      Rails.logger.info(@service.errors.full_messages)
      render :new
    end
  end

  def edit
    @service = Service.find_by_id(params[:id])
  end

  def update
    @service = Service.find_by_id(params[:id])
    @service.assign_attributes(service_params)
    service_event = ChangeServiceEvent.create(service: @service)
    if @service.valid? && service_event.errors.empty?
      redirect_to admin_path(anchor: :services)
    else
      @service.errors.merge!(service_event.errors)
      Rails.logger.info(@service.errors.full_messages)
      render :edit
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
