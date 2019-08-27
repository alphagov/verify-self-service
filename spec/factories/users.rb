FactoryBot.define do
  factory :user do
    given_name { "John" }
    family_name  { "Doe" }
    email { "test@test.test" }
    password { "validpassword" }
    roles { ROLE::USER_MANAGER }
    session_start_time { Time.now.to_s }
    permissions { UserRolePermissions.new(ROLE::USER_MANAGER, nil) }

    factory :gds_user do
      email { "test.test@digital.cabinet-office.gov.uk" }
      roles { ROLE::GDS }
      permissions { UserRolePermissions.new(ROLE::GDS, "test.test@digital.cabinet-office.gov.uk") }
    end

    factory :certificate_manager_user do
      roles { ROLE::CERTIFICATE_MANAGER }
      permissions { UserRolePermissions.new(ROLE::CERTIFICATE_MANAGER, nil) }
    end

    factory :user_manager_user do
      roles { ROLE::USER_MANAGER }
      permissions { UserRolePermissions.new(ROLE::USER_MANAGER, nil) }
    end

    factory :component_manager_user do
      roles { ROLE::COMPONENT_MANAGER }
      permissions { UserRolePermissions.new(ROLE::COMPONENT_MANAGER, nil) }
    end
  end
end
