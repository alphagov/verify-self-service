namespace :smoke_tests do
  desc 'Run smoke tests'
  task :run do
    sh 'bundle exec rspec system/smoke'
  end
end
