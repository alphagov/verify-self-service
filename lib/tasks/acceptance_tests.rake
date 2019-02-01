namespace :acceptance_tests do
  desc 'Run acceptance tests'
  task :run, [:url] do |task, args|
    #Example command: bundle exec rake acceptance_tests:run[verify-self-service-dev.cloudapps.digital]
    sh "TEST_URL=#{args[:url]} bundle exec rspec spec/system/acceptance --tag acceptance"
  end
end
