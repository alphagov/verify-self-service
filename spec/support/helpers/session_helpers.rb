module System
  module SessionHelpers
    def sign_in(email, password)
      visit new_user_session_path
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      click_button 'Log in'
    end

    def login_user
      user = FactoryBot.create(:user_manager_user)
      login_as(user, scope: :user)
    end

    def login_gds_user
      user = FactoryBot.create(:gds_user)
      login_as(user, scope: :user)
    end

    def login_component_manager_user
      user = FactoryBot.create(:component_manager_user)
      login_as(user, scope: :user)
    end

    def login_gds_user
      user = FactoryBot.create(:gds_user)
      login_as(user, :scope => :user)
    end

    def login_component_manager_user
      user = FactoryBot.create(:component_manager_user)
      login_as(user, :scope => :user)
    end

    def login_certificate_manager_user
      user = FactoryBot.create(:certificate_manager_user)
      login_as(user, scope: :user)
    end
  end
end
