class CertificatesController < ApplicationController
  def index
  end

  def upload
    @upload = Certificate.new
    @uploads = Certificate.all
  end

  def create
    @upload = Certificate.create(upload_params)
    redirect_to '/upload'
  end

  private

  def upload_params
    params.require(:certificate).permit(
      :value,
      :usage
    )
  end

end
