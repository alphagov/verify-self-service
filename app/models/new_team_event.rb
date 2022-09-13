require 'auth/authentication_backend'

class NewTeamEvent < AggregatedEvent
  include AuthenticationBackend

  belongs_to_aggregate :team
  data_attributes :name, :team_alias, :team_type

  validates_presence_of :name, message: I18n.t('team.errors.blank_name')
  validates_presence_of :team_type, message: I18n.t('team.errors.team_type_invalid')

  validate :create_cognito_group

  def build_team
    Team.new
  end

  def attributes_to_apply
    {
      name: name,
      team_alias: team_alias,
      team_type: team_type,
      created_at: created_at,
    }
  end

  def create_cognito_group
    return if name.blank?

    create_group(name: team_alias, description: name)
  rescue AuthenticationBackend::GroupExistsException
    Rails.logger.warn("The group #{name} already existed in Cognito...")
  rescue AuthenticationBackend::AuthenticationBackendException => e
    Rails.logger.error("#{I18n.t('team.errors.failed')} -> #{e.message}")
    errors.add(:team, I18n.t('team.errors.failed'))
  end

  def team_alias
    @team_alias ||= unless name.blank?
                      name.delete(' ').strip.match(TEAMS::GROUP_NAME_REGEX)[0]
                    end
  end
end
