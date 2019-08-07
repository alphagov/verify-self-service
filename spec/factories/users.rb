FactoryBot.define do
  factory :user do
    given_name { "John" }
    family_name  { "Doe" }
    email { "test@test.test" }
    password { "validpassword" }
    roles { ROLE::USER_MANAGER }
    permissions { UserRolePermissions.new(ROLE::USER_MANAGER, nil) }
  end

  factory :certificate_manager_user, class: User do
    given_name { "Jane" }
    family_name  { "Smith" }
    email { "test@test.test" }
    password { "validpassword" }
    roles { ROLE::CERTIFICATE_MANAGER }
    permissions { UserRolePermissions.new(ROLE::CERTIFICATE_MANAGER, nil) }
  end
end
