require 'rspec/core/rake_task'

desc 'Run acceptance tests'
RSpec::Core::RakeTask.new(:acceptance_tests) do |t|
  t.pattern = 'spec/acceptance/*_spec.rb'
  t.rspec_opts = "--tag acceptance"
end