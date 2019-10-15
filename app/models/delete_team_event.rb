require 'auth/authentication_backend'

class DeleteTeamEvent < AggregatedEvent
  include AuthenticationBackend

  belongs_to_aggregate :team
  after_save :destroy

  validate :delete_cognito_group

  def attributes_to_apply
    {}
  end

  def delete_cognito_group
    if cognito_group_empty?
      delete_group(name: team.team_alias)
    else
      errors.add(:team, I18n.t('team.errors.not_empty'))
    end
  rescue AuthenticationBackend::AuthenticationBackendException => e
    Rails.logger.error("#{I18n.t('team.errors.failed_to_delete')} -> #{e.message}")
    errors.add(:team, I18n.t('team.errors.failed_to_delete'))
  end

private

  def destroy
    team.destroy!
  end

  def cognito_group_empty?
    get_users_in_group(group_name: team.team_alias).empty?
  end
end
