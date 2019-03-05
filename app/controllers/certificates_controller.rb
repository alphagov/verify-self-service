class CertificatesController < ApplicationController
  def index
    @uploads = Certificate.all
  end

  def upload
    @upload = Certificate.new
  end

  def create
    @upload = Certificate.create(upload_params)
    redirect_to certificates_path
  end

  private

  def upload_params
    params.require(:certificate).permit(
      :value,
      :usage
    )
  end

end
