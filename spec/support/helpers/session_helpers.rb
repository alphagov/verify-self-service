module System
  module SessionHelpers
    def sign_in(email, password)
      visit new_user_session_path
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      click_button 'Log in'
    end

    def login_user
      user = FactoryBot.create(:user)
      login_as(user, :scope => :user)
    end
  end
end
