require 'rails_helper'

RSpec.describe AuthController, type: :controller do
  before(:each) do
    request.env['omniauth.auth'] = auth_hash = OmniAuth::AuthHash.new({'extra' => { 'raw_info' =>{
            'uid' => '12032019',
            'info' => {
            'name' => 'Test User'
            }
        }}, 'provider' => 'twitter'})
  end


  describe 'GET #callback' do
    it 'returns redirect to / if no path set in session' do
      get :callback
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to('/')
    end
    
    it 'returns redirect to path if set in session' do
      session[:redirect_path] = '/test'
      get :callback
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to('/test')
    end
  end

  describe 'GET #failure' do
    it 'returns http success' do
      get :failure
      expect(response).to have_http_status(:success)
    end
  end

end
