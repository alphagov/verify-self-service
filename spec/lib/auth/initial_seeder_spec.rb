require 'rails_helper'
require 'auth/initial_seeder'

RSpec.describe InitialSeeder do
  include CognitoSupport

  let(:users_without_gds){
    {:users=>
          [
            {:username=>"00000-0000-0000-000",
             :attributes=>
             [{:name=> "sub", :value=> "123"},
              {:name=>"given_name", :value=>"Test"},
              {:name=>"family_name", :value=>"Test"},
              {:name=>"email", :value=>"test@test.test"}],
            :user_create_date=>Time.now,
            :user_status=>"CONFIRMED"},
           {:username=>"00000-0000-0000-001",
            :attributes=>
             [{:name=>"sub", :value=>"124"},
              {:name=>"custom:roles", :value=>"usermgr"},
              {:name=>"given_name", :value=>"Test"},
              {:name=>"family_name", :value=>"Testerator"},
              {:name=>"email", :value=>"some@user.com"}],
            :user_create_date=>Time.now,
            :user_status=>"CONFIRMED"},
           {:username=>"00000-0000-0000-002",
            :attributes=>
             [{:name=>"sub", :value=>"125"},
              {:name=>"custom:roles", :value=>"usermgr"},
              {:name=>"given_name", :value=>"User"},
              {:name=>"family_name", :value=>"Admin"},
              {:name=>"email", :value=>"admin@digital.cabinet-office.gov.uk"}],
            :user_create_date=>Time.now,
            :enabled=>true,
            :user_status=>"CONFIRMED"}
          ]
      }
  }
  let(:users_with_gds){
    {:users=>
          [
            {:username=>"00000-0000-0000-000",
             :attributes=>
             [{:name=> "sub", :value=> "123"},
              {:name=>"email_verified", :value=>"true"},
              {:name=>"given_name", :value=>"Test"},
              {:name=>"family_name", :value=>"Test"},
              {:name=>"email", :value=>"test@test.test"}],
            :user_create_date=>Time.now,
            :user_last_modified_date=>Time.now,
            :enabled=>true,
            :user_status=>"CONFIRMED"},
           {:username=>"00000-0000-0000-001",
            :attributes=>
             [{:name=>"sub", :value=>"124"},
              {:name=>"custom:roles", :value=>"usermgr"},
              {:name=>"given_name", :value=>"Test"},
              {:name=>"family_name", :value=>"Testerator"},
              {:name=>"email", :value=>"some@user.com"}],
            :user_create_date=>Time.now,
            :user_status=>"CONFIRMED"},
           {:username=>"00000-0000-0000-002",
            :attributes=>
             [{:name=>"sub", :value=>"125"},
              {:name=>"custom:roles", :value=>"gds"},
              {:name=>"given_name", :value=>"User"},
              {:name=>"family_name", :value=>"Admin"},
              {:name=>"email", :value=>"admin@digital.cabinet-office.gov.uk"}],
            :user_create_date=>Time.now,
            :user_status=>"CONFIRMED"}
          ]
    }
  }
  let(:users_with_gds_but_not_gds_email){
   
          [
            {username:"00000-0000-0000-000",
             attributes:
             [{:name=> "sub", :value=> "123"},
              {:name=>"given_name", :value=>"Test"},
              {:name=>"family_name", :value=>"Test"},
              {:name=>"email", :value=>"test@test.test"}],
            :user_create_date=>Time.now,
            :user_status=>"CONFIRMED"},
           {username:"00000-0000-0000-001",
            attributes:
             [{:name=>"sub", :value=>"124"},
              {:name=>"custom:roles", :value=>"usermgr"},
              {:name=>"given_name", :value=>"Test"},
              {:name=>"family_name", :value=>"Testerator"},
              {:name=>"email", :value=>"some@user.com"}],
            :user_create_date=>Time.now,
            :user_status=>"CONFIRMED"},
           {username:"00000-0000-0000-002",
            attributes:
             [{:name=>"sub", :value=>"125"},
              {:name=>"custom:roles", :value=>"gds"},
              {:name=>"given_name", :value=>"User"},
              {:name=>"family_name", :value=>"Admin"},
              {:name=>"email", :value=>"admin@non-gds.com"}],
            :user_create_date=>Time.now,
            :user_status=>"CONFIRMED"}
          ]
    
  }

  describe '#gds_group_exists?' do
    it 'returns true when both Cognito group and the GDS Team exist' do
      stub_cognito_response(method: :get_group, payload: {})
      Team.create(name:TEAMS::GDS, team_alias: TEAMS::GDS)
      expect(subject.gds_group_exists?).to eq(true)
    end
    it 'returns false when Cognito group exists but GDS Team does not' do
      stub_cognito_response(method: :get_group, payload: {})
      expect(subject.gds_group_exists?).to eq(false)
    end
    it 'returns false when Cognito group does not exist' do
      stub_cognito_response(
        method: :get_group, 
        payload: Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException.new(nil, nil))
      expect(subject.gds_group_exists?).to eq(false)
    end
    it 'returns false when Cognito throws an error' do
      stub_cognito_response(
        method: :get_group, 
        payload: Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, nil))
      expect(subject.gds_group_exists?).to eq(false)
    end
  end

  describe '#gds_user_exists?' do
    it 'returns number of GDS users found if there are any' do
      stub_cognito_response(method: :list_users, payload: users_with_gds)
      expect(subject.gds_user_exists?).to eq(1)
    end
    it 'returns zero if zero number of GDS users found' do
      stub_cognito_response(method: :list_users, payload: users_without_gds)
      expect(subject.gds_user_exists?).to eq(0)
    end
    it 'returns false when Cognito throws an error' do
      stub_cognito_response(
        method: :list_users, 
        payload: Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, nil))
      expect(subject.gds_user_exists?).to eq(false)
    end
  end

  describe '#add_gds_users_to_group' do
    it 'adds 1 GDS user to the GDS group when 1 user has both GDS role and GDS email' do
      gds_users = JSON.parse(users_with_gds[:users].to_json, object_class: OpenStruct)
      expect(SelfService.service(:cognito_client)).to receive(:admin_add_user_to_group).once
      subject.add_gds_users_to_group(gds_users)
    end
    it 'adds none GDS user to the GDS group when 1 user has GDS role but not GDS email' do
      gds_users = JSON.parse(users_with_gds_but_not_gds_email.to_json, object_class: OpenStruct)
      expect(SelfService.service(:cognito_client)).to_not receive(:admin_add_user_to_group)
      subject.add_gds_users_to_group(gds_users)
    end
  end
end