Rails.application.routes.draw do
  get '/upload', to: 'home#upload'
  post '/upload', to: 'home#create'

  root 'home#index'
end
