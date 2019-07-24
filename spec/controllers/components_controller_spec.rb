require 'rails_helper'

RSpec.describe ComponentsController, type: :controller do
    include AuthSupport

    it "should redirect to sign-page" do
        get :index
        expect(response).to have_http_status(:redirect)
        expect(subject).to redirect_to(new_user_session_path)
        expect(subject).not_to redirect_to(root_path)
    end

    it "should render when logged in" do
        stub_auth
        get :index
        expect(response).to have_http_status(:success)
        expect(subject).not_to redirect_to(new_user_session_path)
        expect(subject).to render_template(:index)
    end
end 