module ErrorsHelper
  def upload_errors?(upload)
    upload.errors.any?
  end
end
