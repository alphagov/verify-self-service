class CertificatesController < ApplicationController
  def new
    @upload = UploadCertificateEvent.new
  end

  def create
    @upload = UploadCertificateEvent.create(upload_params)
    if @upload.valid?
      component = Component.find(@upload.component_id)
      if @upload.certificate.usage == 'encryption'
        component.encryption_certificate_id = @upload.certificate.id
        component.save
      end
      redirect_to component_path(@upload.component_id)
    else
      Rails.logger.info(@upload.errors.full_messages)
      render :new
    end
  end

  def enable
    @certificate = Certificate.find(params[:id])
    event = EnableSigningCertificateEvent.create(certificate: @certificate)
    unless event.valid?
      error_message = event.errors.full_messages
      Rails.logger.error(error_message)
      flash[:notice] = error_message
    end
    redirect_to component_path(@certificate.component_id)
  end

  def disable
    @certificate = Certificate.find(params[:id])
    event = DisableSigningCertificateEvent.create(certificate: @certificate)
    unless event.valid?
      error_message = event.errors.full_messages
      Rails.logger.error(error_message)
      flash[:notice] = error_message
    end
    redirect_to component_path(@certificate.component_id)
  end

  private

  def upload_params
    component_id ||= params[:component_id]

    params.require(:certificate)
          .permit(:value, :usage)
          .merge(component_id: component_id)
  end
end