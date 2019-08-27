require 'rails_helper'

RSpec.describe AdminController, type: :controller do
  include AuthSupport

    it 'should render when GDS user' do
      gdsuser_stub_auth
      get :index
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:index)
    end

    it 'should not render when user is certificate manager' do
      certmgr_stub_auth
      get :index
      expect(flash[:warn]).to eq 'You are not authorised to perform this action'      
      expect(subject).to_not render_template(:index)
    end

    it 'should not render when user is user manager' do
      usermgr_stub_auth
      get :index
      expect(flash[:warn]).to eq 'You are not authorised to perform this action'      
      expect(subject).to_not render_template(:index)
    end
end
