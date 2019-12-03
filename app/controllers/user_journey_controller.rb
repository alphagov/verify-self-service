class UserJourneyController < ApplicationController
  layout "main_layout"
  include ControllerConcern
  include ComponentConcern
  include CertificateConcern
  include X509Validator

  before_action :find_certificate, except: :index
  helper_method :error_class, :checked, :text_box_value
  before_action :dual_running, except: :index
  before_action :find_team_name


  def index
    if current_user.permissions.component_management
      @components = SpComponent.all + MsaComponent.all
    else
      @components = SpComponent.for_user(current_user) + MsaComponent.for_user(current_user)
    end
    @total_certificates_expiring_soon = helpers.certificate_expiry_count(@components)
  end

  def is_dual_running
    if params.key?(:dual_running)
      if @not_dual_running
        redirect_to before_you_start_path(dual_running: @not_dual_running)
      else
        redirect_to :before_you_start
      end
    else
      Rails.logger.info(@not_dual_running)
      redirect_to dual_running_path, flash: { error: I18n.t('user_journey.errors.select_option') }
    end
  end

  def upload_certificate
    @upload = UploadCertificateEvent.new(
      component_id: @certificate.component_id,
      component_type: @certificate.component_type,
    )
  end

  def disable_certificate
    event = DisableSigningCertificateEvent.create(certificate: @certificate)
    if event.errors.empty?
      check_metadata_published(event.id)
      redirect_to root_path
    else
      flash[:error] = event.errors.full_messages
      render :view_certificate
    end
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
      component_id: @certificate.component_id,
      component_type: @certificate.component_type,
    )

    if @upload.valid?
      component = klass_component(@upload.component_type).find_by_id(@upload.component_id)
      if @upload.certificate.encryption?
        replace = ReplaceEncryptionCertificateEvent.create(
          component: component,
          encryption_certificate_id: @upload.certificate.id,
        )
        replaced_certicate_published = check_metadata_published_user_journey(replace.id)
      end

      certicate_published = check_metadata_published_user_journey(@upload.id)

      if certicate_published && replaced_certicate_published
        render :confirmation
      else
        render :publish_failed
      end
    else
      Rails.logger.info(@upload.errors.full_messages.join(', '))
      render :upload_certificate
    end
  end

private

  def find_certificate
    @certificate = Certificate.find_by_id(params[:certificate_id])
    redirect_to root_path if @certificate.nil?
  end

  def dual_running
    @not_dual_running = params[:dual_running].blank? ? nil : true
  end

  def find_team_name
    @team_name = Team.find_by_id(current_user.team).name unless current_user.team.nil?
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
