require 'rails_helper'
require 'data/integrity_checker'

RSpec.describe IntegrityChecker do
  include CognitoSupport

  let(:groups) {
    { groups: [
      {
        group_name: 'testteam1',
        user_pool_id: 'one',
        description: 'test team1',
        role_arn: nil,
        precedence: nil,
        last_modified_date: Time.now,
        creation_date: Time.now
      },
      {
        group_name: 'testteam2',
        user_pool_id: 'one',
        description: 'test team2',
        role_arn: nil,
        precedence: nil,
        last_modified_date: Time.now,
        creation_date: Time.now
      },
      {
        group_name: 'testteam3',
        user_pool_id: 'one',
        description: 'test team3',
        role_arn: nil,
        precedence: nil,
        last_modified_date: Time.now,
        creation_date: Time.now
      },
    ]}
  }

  describe 'IntegrityChecker' do
    it 'creates the teams so they match with cognito groups' do
      stub_cognito_response(method: :list_groups, payload: groups)
      stub_cognito_response(method: :create_group, payload: {})
      groups[:groups].each do |group|
        expect(Team.exists?(team_alias: group[:group_name])).to eq false
      end
      subject.check_groups_vs_teams
      groups[:groups].each do |group|
        expect(Team.exists?(team_alias: group[:group_name])).to eq true
      end
    end
  end
end