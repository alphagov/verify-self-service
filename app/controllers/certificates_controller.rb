class CertificatesController < ApplicationController
  def new
    @upload = UploadCertificateEvent.new
  end

  def create
    @upload = UploadCertificateEvent.create(upload_params)

    if @upload.valid?
      redirect_to component_path @upload.component_id
    else
      Rails.logger.info(@upload.errors.full_messages)
      render 'new'
    end
  end

  private

  def upload_params
    cert_params = params.require(:certificate).permit(
      :value,
      :usage
    )

    if !params[:component_id].nil?
      cert_params.merge(component_id: params[:component_id])
    elsif is_integer?(nested_param_key_after_failed_validation)
      cert_params.merge(component_id: nested_param_key_after_failed_validation)
    else
      Rails.logger.info("component_id not valid")
      nil
    end
  end

  def is_integer?(component_id)
    component_id.to_i.to_s == component_id
  end

  def nested_param_key_after_failed_validation
    params["certificate"]["component_id"]
  end
end
