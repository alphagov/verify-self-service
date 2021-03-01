FactoryBot.define do
  factory :user do
    user_id { SecureRandom.uuid }
    first_name { 'John' }
    last_name  { 'Doe' }
    email { 'test@test.test' }
    password { 'validpassword' }
    roles { ROLE::USER_MANAGER }
    cognito_groups { ['test'] }
    team { create(:team).id }
    session_start_time { Time.now.to_s }
    access_token { SecureRandom.uuid }

    factory :gds_user do
      email { 'test.test@digital.cabinet-office.gov.uk' }
      roles { ROLE::GDS }
      permissions { UserRolePermissions.new(ROLE::GDS, 'test.test@digital.cabinet-office.gov.uk') }
    end

    factory :certificate_manager_user do
      roles { ROLE::CERTIFICATE_MANAGER }
      permissions { UserRolePermissions.new(ROLE::CERTIFICATE_MANAGER) }
    end

    factory :user_manager_user do
      roles { ROLE::USER_MANAGER }
      permissions { UserRolePermissions.new(ROLE::USER_MANAGER) }
    end

    factory :rp_user_manager_user do
      roles { ROLE::USER_MANAGER }
      permissions { UserRolePermissions.new(ROLE::USER_MANAGER) }
      team { create(:team, team_type: 'rp').id }
    end

    factory :idp_user_manager_user do
      roles { ROLE::USER_MANAGER }
      permissions { UserRolePermissions.new(ROLE::USER_MANAGER) }
      team { create(:team, team_type: 'idp').id }
    end

    factory :component_manager_user do
      roles { ROLE::COMPONENT_MANAGER }
      permissions { UserRolePermissions.new(ROLE::COMPONENT_MANAGER) }
    end
  end
end
