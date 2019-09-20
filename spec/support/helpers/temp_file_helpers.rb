module TempFileHelpers
  def upload_file(name:, type:, content:)
    Rack::Test::UploadedFile.new(
      create_tempfile(name: name, content: content).path,
      type
    )
  end

  def create_tempfile(name:, content:)
    Tempfile.new.tap do |f|
      f.write(content)
      f.close
    end
  end
end
