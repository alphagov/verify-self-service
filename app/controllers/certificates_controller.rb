class CertificatesController < ApplicationController
  def new
    @upload = UploadCertificateEvent.new
  end

  def create
    @upload = UploadCertificateEvent.create(upload_params)

    if @upload.valid?
      redirect_to component_path(@upload.component_id)
    else
      Rails.logger.info(@upload.errors.full_messages)
      render :new
    end
  end

  def update
    @certificate = Certificate.find(params[:id])

    if @certificate.enabled
      DisableSigningCertificateEvent.create(certificate: @certificate)
    else
      EnableSigningCertificateEvent.create(certificate: @certificate)
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

  def update_params
    params.require(:certificate)
        .permit(:enabled)
  end
end