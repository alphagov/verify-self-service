class UserJourneyController < ApplicationController
  layout "main_layout"
  include ControllerConcern
  include ComponentConcern
  include CertificateConcern
  include X509Validator

  before_action :find_certificate, except: :index
  helper_method :error_class, :checked, :text_box_value

  def index
    if current_user.permissions.component_management
      @sp_components = SpComponent.all
      @msa_components = MsaComponent.all
    else
      @sp_components = SpComponent.where(team_id: current_user.team)
      @msa_components = MsaComponent.where(team_id: current_user.team)
    end
  end

  def before_you_start
    @dual_running = params[:dual_running]
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
        render 'user_journey/check_your_certificate'
        return
      end
    end

    # For the purposes of the form :(
    @upload = extractor
    Rails.logger.info(merge_errors(@upload, @new_certificate))
    render :upload_certificate
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
      Rails.logger.info(@upload.errors.full_messages.join(', '))
      render :upload_certificate
    end
  end

private

  def find_certificate
    @certificate = Certificate.find_by_id(params[:certificate_id])
  end

  def merge_errors(primary, *objects)
    objects.compact.each { |object| primary.errors.merge!(object.errors) }
    primary.errors.full_messages.join(', ')
  end

  def error_class(type)
    if errors_present?
      if type == 'file' && params['upload-certificate'] == 'file'
        'govuk-file-upload--error'
      elsif type == 'string' && params['upload-certificate'] == 'string'
        'govuk-textarea--error'
      end
    end
  end

  def checked(type)
    if errors_present? && type == params['upload-certificate']
      "checked=checked"
    end
  end

  def text_box_value
    if errors_present? && params['upload-certificate'] == 'string'
      params[:certificate][:value]
    end
  end

  def errors_present?
    (%i(certificate value cert_file) & @upload.errors.keys).any?
  end
end
