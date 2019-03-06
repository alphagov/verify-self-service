Rails.application.routes.draw do
  get 'home/index', to: 'home#index'
  get '/upload', to: 'certificates#upload'
  post '/upload', to: 'certificates#create'

  get '/certificates', to: 'certificates#index'
  root 'certificates#index'
  get '/events', to: 'events#index'
  get '/events/:page', to: 'events#page'
end
