require 'auth/authentication_backend'
# The purpose of this is to make sure any existing Cognito groups
# have a corresponding local team in DB. If not, it creates them.

class IntegrityChecker
  include AuthenticationBackend

  def initialize
    return if SelfService.service(:cognito_stub)

    Rails.logger.info('Checking the data integrity...')
    check_groups_vs_teams
  end

  def check_groups_vs_teams
    cognito_groups = list_groups
    return if cognito_groups.empty?

    cognito_groups.groups.each do |group|
      Rails.logger.info("Checking if #{group.group_name} group has a corresponding team in DB...")
      if Team.exists?(team_alias: group.group_name)
        Rails.logger.info("OK - #{group.group_name} group has a corresponding team in DB...")
      else
        Rails.logger.warn("#{group.group_name} group does not have a corresponding team in DB! Creating...")
        NewTeamEvent.create(name: group.description)
      end
    end
  end
end
