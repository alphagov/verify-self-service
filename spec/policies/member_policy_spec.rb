require 'rails_helper'

describe MemberPolicy do
  include CognitoSupport
  subject { MemberPolicy }

  let(:user_id) { SecureRandom::uuid }
  let(:member_id) { SecureRandom::uuid }

  let(:cognito_users) {
    { users: [
      { username: member_id,
        attributes: [
                      { name: "given_name", value: "Apple" },
                      { name: "family_name", value: "One" },
                      { name: "email", value: "apple.one@test.com" },
                      { name: "custom:roles", value: "usermgr" }
                     ]
      },
      { username: user_id,
       attributes: [
                     { name: "given_name", value: "Apple" },
                     { name: "family_name", value: "Two" },
                     { name: "email", value: "apple.two@test.com" },
                     { name: "custom:roles", value: "certmgr,usermgr" }
                   ]
      }
    ]}
  }

  let(:cognito_user) {
    { username: user_id,
      user_attributes: [
                         { name: "given_name", value: "Apple" },
                         { name: "family_name", value: "Two" },
                         { name: "email", value: "apple.two@test.com" },
                         { name: "custom:roles", value: "certmgr,usermgr" }
                       ]
    }
  }

  permissions :show?, :update? do
    it "denies access when the user attempts to edit a member of another team" do
      member = Member.new("12345")

      expect(subject).not_to permit(create(:user_manager_user), member)
    end

    it "allows access when the user attempts to edit a member of their own team" do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)

      member = Member.new(member_id)
      user = create(:user_manager_user, user_id: user_id)

      expect(subject).to permit(user, member)
    end

    it "denies access when the user attempts to edit their own permissions" do
      user = create(:user_manager_user)
      member = Member.new(user.user_id)

      expect(subject).not_to permit(user, member)
    end

    it 'grants access when GDS user' do
      member = Member.new(member_id)

      expect(subject).to permit(create(:gds_user), member)
    end
  end
end
