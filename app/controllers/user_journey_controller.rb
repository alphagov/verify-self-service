class UserJourneyController < ApplicationController
  layout "main_layout"
  include ControllerConcern
  include ComponentConcern
  include CertificateConcern
  include X509Validator

  before_action :find_certificate, except: :index

  def index
    if current_user.permissions.component_management
      @sp_components = SpComponent.all
      @msa_components = MsaComponent.all
    else
      @sp_components = SpComponent.where(team_id: current_user.team)
      @msa_components = MsaComponent.where(team_id: current_user.team)
    end
  end

  def upload_certificate
    component_id = params[component_key(params)]
    component_type = component_name_from_params(params)
    @upload = UploadCertificateEvent.new(
      component_id: component_id,
      component_type: component_type,
    )
  end

  def submit
    extractor = CertificateExtractor.new(params)

    if extractor.valid?
      @new_certificate_value = extractor.call
      @component = klass_component(@certificate.component_type).find_by_id(@certificate.component_id)
      @new_certificate = Certificate.new(
        usage: @certificate.usage,
        value: @new_certificate_value,
        component: @component,
      )

      if @new_certificate.valid? && valid_x509?(@new_certificate)
        render "user_journey/check_your_certificate"
        return
      end
    end

    error_message = extractor.tap { |x|
      x.errors.merge!(@new_certificate.errors) if @new_certificate
    }.errors.full_messages.join(", ")

    Rails.logger.info(error_message)
    redirect_to :upload_certificate, flash: { error: error_message }
  end

  def confirm
    new_certificate_value = params[:certificate][:new_certificate]
    @upload = UploadCertificateEvent.create(
      usage: @certificate.usage,
      value: new_certificate_value,
      component_id: params[:component_id],
      component_type: params[:component_type],
    )

    if @upload.valid?
      component = klass_component(@upload.component_type).find_by_id(@upload.component_id)

      if @upload.certificate.encryption?
        ReplaceEncryptionCertificateEvent.create(
          component: component,
          encryption_certificate_id: @upload.certificate.id,
        )
      end

      render :confirmation
    else
      @upload.errors.full_messages.join(", ").tap do |error_message|
        Rails.logger.info(error_message)
        flash.now[:error] = error_message
      end

      render :upload_certificate
    end
  end

private

  def find_certificate
    @certificate = Certificate.find_by_id(params[:certificate_id])
  end
end
