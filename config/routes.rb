Rails.application.routes.draw do
  get '/upload', to: 'certificates#upload'
  post '/upload', to: 'certificates#create'

  root 'certificates#index'
end
