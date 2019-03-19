require 'fileutils'

desc 'Copy govuk-frontend assets'
task 'copy_govuk_dependencies' do
  source = 'node_modules/govuk-frontend/assets/'
  destination = 'public/assets/govuk-frontend/assets/'

  dirname = File.dirname(destination)
  FileUtils.mkdir_p(dirname)
  FileUtils.copy_entry source, destination
end