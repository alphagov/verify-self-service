class CertificatesController < ApplicationController
  include ControllerConcern
  include ComponentConcern

  def new
    component_id = params[component_key(params)]
    component_type = component_name_from_params(params)
    @upload = UploadCertificateEvent.new(
      component_id: component_id,
      component_type: component_type
    )
  end

  def create
    @upload = UploadCertificateEvent.create(upload_params)
    if @upload.valid?
      component = klass_component(@upload.component_type).find_by_id(@upload.component_id)

      if @upload.certificate.encryption?
        ReplaceEncryptionCertificateEvent.create(
          component: component,
          encryption_certificate_id: @upload.certificate.id
        )
      end

      redirect_to polymorphic_url(component)
    else
      Rails.logger.info(@upload.errors.full_messages)
      render :new
    end
  end

  def enable
    certificate = Certificate.find_by_id(params[:id])
    event = EnableSigningCertificateEvent.create(certificate: certificate)
    unless event.valid?
      error_message = event.errors.full_messages
      Rails.logger.error(error_message)
      flash[:notice] = error_message
    end
    redirect_to polymorphic_url(
      klass_component(certificate.component_type).find_by_id(certificate.component_id)
    )
  end

  def disable
    certificate = Certificate.find_by_id(params[:id])
    event = DisableSigningCertificateEvent.create(certificate: certificate)
    unless event.valid?
      error_message = event.errors.full_messages
      Rails.logger.error(error_message)
      flash[:notice] = error_message
    end
    redirect_to polymorphic_url(
      klass_component(certificate.component_type).find_by_id(certificate.component_id)
    )
  end

  def replace
    component = klass_component(
      component_name_from_params(params)
    ).find_by_id(params[:component])
    certificate = Certificate.find_by_id(params[:id])
    event = ReplaceEncryptionCertificateEvent.create(
      component: component,
      encryption_certificate_id: certificate.id
    )
    unless event.valid?
      error_message = event.errors.full_messages
      flash[:notice] = error_message
    end
    redirect_to polymorphic_url(component)
  end

private

  def upload_params
    component_id = params[component_key(params)]
    component_type = component_name_from_params(params)

    params.require(:certificate)
          .permit(:value, :usage)
          .merge(
            component_id: component_id,
            component_type: component_type
          )
  end
end
