
    def stub_auth
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new({
            'uid' => '12032019',
            'provider' => 'twitter',
            'info' => {
            'name' => 'Test User'
            }
        })
        OmniAuth.config.add_mock(:cognito_idp, {:provider => 'cognito-idp'})
        Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:cognito_idp]
    end
