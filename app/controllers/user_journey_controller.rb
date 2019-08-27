class UserJourneyController < ApplicationController
  layout "main_layout"
  include ControllerConcern
  include ComponentConcern
  include CertificateConcern

  before_action :find_certificate

  def index
    @sp_components = SpComponent.all
    @msa_components = MsaComponent.all
  end

  def upload_certificate
    component_id = params[component_key(params)]
    component_type = component_name_from_params(params)
    @upload = UploadCertificateEvent.new(
      component_id: component_id,
      component_type: component_type
    )
  end

  def submit
    @new_certificate_value = (params[:certificate][:value])
    @component = klass_component(@certificate.component_type).find_by_id(@certificate.component_id)
    @new_certificate = Certificate.new(usage: @certificate.usage, value: @new_certificate_value, component: @component)
    if @new_certificate.valid?
      render 'user_journey/check_your_certificate'
    else
      redirect_to :upload_certificate
    end
  end

  def confirm
    new_certificate_value = params[:certificate][:new_certificate]
    @upload = UploadCertificateEvent.create(usage: @certificate.usage, value: new_certificate_value, component_id: params[:component_id], component_type: params[:component_type])

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
      render :upload_certificate
    end
  end

  def find_certificate
    @certificate = Certificate.find_by_id(params[:certificate_id])
  end
end
