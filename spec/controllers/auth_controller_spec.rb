require 'rails_helper'
require 'auth_test_helper'

RSpec.describe AuthController, type: :controller do
  before(:each) do
    get_auth_hash
  end


  describe 'GET #callback' do
    it 'returns redirect to / if no path set in session' do
      get :callback, params: { provider: 'test-idp' }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to root_path
    end

    it 'returns redirect to path if set in session' do
      session[:redirect_path] = '/test'
      get :callback, params: { provider: 'test-idp' }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to '/test'
    end
  end

  describe 'GET #failure' do
    it 'returns http success' do
      get :failure
      expect(response).to have_http_status(:success)
    end
  end

end
