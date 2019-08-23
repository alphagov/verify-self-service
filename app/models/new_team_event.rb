class NewTeamEvent < AggregatedEvent
  belongs_to_aggregate :team
  data_attributes :name, :team_alias

  validate :name_is_present, :create_cognito_group

  def build_team
    Team.new
  end

  def attributes_to_apply
    {
      name: name,
      team_alias: team_alias,
      created_at: created_at
    }
  end

  def create_cognito_group
    return if name.blank?

    SelfService.service(:cognito_client).create_group(
      group_name: team_alias,
      description: name,
      user_pool_id: Rails.configuration.cognito_user_pool_id
    )
  rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException => e
    Rails.logger.error("#{I18n.t('team.errors.invalid')} -> #{e.message}")
    errors.add(:team, I18n.t('team.errors.invalid'))
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    Rails.logger.error("#{I18n.t('team.errors.failed')} -> #{e.message}")
    errors.add(:team, I18n.t('team.errors.failed'))
  end

  def team_alias
    @team_alias ||= begin
      unless name.blank?
        name.delete(' ').strip.match(TEAMS::GROUP_NAME_REGEX)[0]
      end
    end
  end
end
