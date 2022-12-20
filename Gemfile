source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.6'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.7'
# Use postgres as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 6.0.1'
# Use SCSS for stylesheets
gem 'sassc-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false
gem 'colorize'

gem 'kaminari', '~> 1.2'

gem 'aws-sdk-cognitoidentityprovider'
gem 'aws-sdk-s3'

gem 'devise'
gem 'jwt'
gem 'pundit'
gem 'request_store'
gem 'rqrcode'
gem 'rufus-scheduler'

gem 'notifications-ruby-client'
gem 'email_validator'

gem 'sentry-raven'

gem 'faraday'
gem 'mimemagic', '~> 0.4.3'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capybara', '~> 3.35'
  gem 'factory_bot_rails'
  gem 'rubocop-govuk'
  gem 'scss_lint-govuk'
  gem 'pry'
  gem 'rack_session_access'
  gem 'rails-controller-testing'
  gem 'rspec', '~> 3.12'
  gem 'rspec-rails', '~> 6.0'
  gem 'selenium-webdriver', '~> 4'
  gem 'webdrivers', '~> 5.2'
  gem 'webmock', require: false
  gem 'rotp'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.8'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'dotenv-rails', require: 'dotenv/rails-now', group: %i[development test]
