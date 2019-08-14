class UserJourneyController < ApplicationController
  layout "main_layout"
  include ControllerConcern
  include ComponentConcern
  include CertificateConcern

  def index
    @sp_components = SpComponent.all
    @msa_components = MsaComponent.all
  end

  def view_certificate
    @certificate = Certificate.find_by_id(params[:id])
  end

  def before_you_start
    @certificate = Certificate.find_by_id(params[:id])
  end

  def replace_certificate
    @certificate = Certificate.find_by_id(params[:id])
    component_id = params[component_key(params)]
    component_type = component_name_from_params(params)
    @upload = UploadCertificateEvent.new(
      component_id: component_id,
      component_type: component_type
    )
  end

  def replace_certificate_post; end

  def check_your_certificate
    @existing_certificate = Certificate.find_by_id(params[:id])
    @certificate_value = (params[:certificate][:value])
    @component = MsaComponent.find_by_id(params[:component_id])

    new_certificate = Certificate.new(usage: @existing_certificate.usage, value: @certificate_value, component: @component)

    if new_certificate.valid?
      @certificate = to_x509(params[:certificate][:value])
    else
      redirect_to :replace_certificate
    end
  end

  def confirmation
    certificate_value = params[:certificate][:new_certificate]
    @existing_certificate = Certificate.find_by_id(params[:id])
    @upload = UploadCertificateEvent.create(usage: @existing_certificate.usage, value: certificate_value, component_id: params[:component_id], component_type: params[:component_type])

    if @upload.valid?
      component = klass_component(@upload.component_type).find_by_id(@upload.component_id)

      if @upload.certificate.encryption?
        ReplaceEncryptionCertificateEvent.create(
          component: component,
          encryption_certificate_id: @upload.certificate.id
        )
      end

      render :confirmation
    else
      Rails.logger.info(@upload.errors.full_messages)
      render :replace_certificate
    end
  end
end
