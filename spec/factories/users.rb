FactoryBot.define do
  factory :user do
    given_name { "John" }
    family_name  { "Doe" }
    email { "test@test.test" }
    password { "validpassword" }
    permissions { UserRolePermissions.new("", nil) }
  end

  factory :certificate_manager_user, class: User do
    given_name { "Jane" }
    family_name  { "Smith" }
    email { "test@test.test" }
    password { "validpassword" }
    roles { "certmgr" }
    permissions { UserRolePermissions.new("certmgr", nil) }
  end
end
