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
    return redirect_to users_path if helpers.idp_team?(current_user&.team)

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
    if @certificate.signing? && @certificate.component.enabled_signing_certificates.count >= 2
      flash[:error] = I18n.t('user_journey.errors.multi_submission')
      redirect_to root_path
    elsif upload_event.invalid?
      Rails.logger.info(upload_event.errors.full_messages.join(', '))
      render :upload_certificate
    elsif upload_event.certificate.signing? && uploaded_certificate_published?
      render :confirmation
    elsif upload_event.certificate.encryption? && uploaded_replaced_certificate_published?
      render :confirmation
    else
      render :publish_failed
    end
  end

private

  def uploaded_certificate_published?
    @uploaded_certificate_published ||= check_metadata_published_user_journey(upload_event.id)
  end

  def uploaded_replaced_certificate_published?
    uploaded_certificate_published? && check_metadata_published_user_journey(replace_event.id)
  end

  def replace_event
    ReplaceEncryptionCertificateEvent.create(
      component: klass_component(upload_event.component_type).find_by_id(upload_event.component_id),
      encryption_certificate_id: upload_event.certificate.id,
    )
  end

  def upload_event
    @upload_event ||= UploadCertificateEvent.create(
      usage: @certificate.usage,
      value: params[:certificate][:new_certificate],
      component_id: @certificate.component_id,
      component_type: @certificate.component_type,
    )
  end

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
    (%i(certificate value cert_file) & @upload.errors.attribute_names).any?
  end
end
