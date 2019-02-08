Rails.application.routes.draw do
  get 'home/index', to: 'home#index'
  get '/upload', to: 'certificates#upload'
  post '/upload', to: 'certificates#create'

  root 'certificates#index'
end
