require 'rails_helper'

RSpec.describe SupportController, type: :controller do
  include AuthSupport

  describe "Support Controller" do
    context "logging in" do
      it "redirects to log-in page if no user" do
        get :index
        expect(response.status).to eq(302)
      end

      it "shows support page if user is logged in" do
        usermgr_stub_auth
        get :index
        expect(response.status).to eq(200)
      end

      describe "GET #index" do
        it "renders the support page" do
          usermgr_stub_auth
          get :index
          expect(response).to have_http_status(:success)
          expect(subject).to render_template(:index)
        end
      end
    end
  end
end
