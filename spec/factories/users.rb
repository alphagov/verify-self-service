FactoryBot.define do
  factory :user do
    given_name { "John" }
    family_name  { "Doe" }
    email { "test@test.test" }
    password { "validpassword" }
    roles { ROLE::USER_MANAGER }
    cognito_groups { ['test'] }
    team { 1 }
    session_start_time { Time.now.to_s }

    factory :gds_user do
      email { "test.test@digital.cabinet-office.gov.uk" }
      roles { ROLE::GDS }
      permissions { UserRolePermissions.new(ROLE::GDS, "test.test@digital.cabinet-office.gov.uk") }
    end

    factory :certificate_manager_user do
      roles { ROLE::CERTIFICATE_MANAGER }
      permissions { UserRolePermissions.new(ROLE::CERTIFICATE_MANAGER) }
    end

    factory :user_manager_user do
      roles { ROLE::USER_MANAGER }
      team { 1 }
      permissions { UserRolePermissions.new(ROLE::USER_MANAGER) }
    end

    factory :component_manager_user do
      roles { ROLE::COMPONENT_MANAGER }
      permissions { UserRolePermissions.new(ROLE::COMPONENT_MANAGER) }
    end
  end
end
