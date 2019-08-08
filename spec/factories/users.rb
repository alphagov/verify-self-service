FactoryBot.define do
  factory :user do
    given_name { "John" }
    family_name  { "Doe" }
    email { "test@test.test" }
    password { "validpassword" }
    roles { ROLE::USER_MANAGER }
    current_sign_in_at { Time.now.to_s }
    last_sign_in_at { Time.now.to_s }
    permissions { UserRolePermissions.new(ROLE::USER_MANAGER, nil) }
  end

  factory :gds_user, class: User do
    given_name { "John" }
    family_name  { "Doe" }
    email { "test.test@digital.cabinet-office.gov.uk" }
    password { "validpassword" }
    roles { ROLE::GDS }
    current_sign_in_at { Time.now.to_s }
    last_sign_in_at { Time.now.to_s }
    permissions { UserRolePermissions.new(ROLE::GDS, "test.test@digital.cabinet-office.gov.uk") }
  end

  factory :certificate_manager_user, class: User do
    given_name { "Jane" }
    family_name  { "Smith" }
    email { "test@test.test" }
    password { "validpassword" }
    roles { ROLE::CERTIFICATE_MANAGER }
    current_sign_in_at { Time.now.to_s }
    last_sign_in_at { Time.now.to_s }
    permissions { UserRolePermissions.new(ROLE::CERTIFICATE_MANAGER, nil) }
  end

  factory :user_manager_user, class: User do
    given_name { "Jane" }
    family_name  { "Smith" }
    email { "test@test.test" }
    password { "validpassword" }
    roles { ROLE::USER_MANAGER }
    current_sign_in_at { Time.now.to_s }
    last_sign_in_at { Time.now.to_s }
    permissions { UserRolePermissions.new(ROLE::USER_MANAGER, nil) }
  end

  factory :component_manager_user, class: User do
    given_name { "Jane" }
    family_name  { "Smith" }
    email { "test@test.test" }
    password { "validpassword" }
    roles { ROLE::COMPONENT_MANAGER }
    current_sign_in_at { Time.now.to_s }
    last_sign_in_at { Time.now.to_s }
    permissions { UserRolePermissions.new(ROLE::COMPONENT_MANAGER, nil) }
  end
end
