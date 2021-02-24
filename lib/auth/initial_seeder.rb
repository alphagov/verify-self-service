require 'auth/authentication_backend'

class InitialSeeder
  include AuthenticationBackend

  def initialize
    return if SelfService.service(:cognito_stub)

    Rails.logger.info('Initializing the seed sequence...')
    create_gds_group unless gds_group_exists?
    if gds_user_exists?
      add_gds_users_to_group
    else
      create_gds_user
    end
  end

  def gds_group_exists?
    begin
      get_group(group_name: TEAMS::GDS)
    rescue AuthenticationBackend::UserGroupNotFoundException
      Rails.logger.warn('The GDS group does not exist in the authentication backend!')
      return false
    rescue AuthenticationBackend::AuthenticationBackendException => e
      Rails.logger.warn("Error occurred when checking GDS group: #{e}")
      return false
    end
    Rails.logger.info('The GDS group already exists in  the authentication backend.')
    if Team.exists?(team_alias: TEAMS::GDS)
      Rails.logger.info('The GDS group already exists in database.')
      true
    else
      Rails.logger.info('The GDS group does not exist in database.')
      false
    end
  end

  def gds_user_exists?
    begin
      @gds_users = find_users_by_role(role: TEAMS::GDS)
    rescue AuthenticationBackend::AuthenticationBackendException => e
      Rails.logger.error("Error occurred when looking for GDS users: #{e}")
      return false
    end
    Rails.logger.info("Found #{@gds_users.length} existing GDS users.")
    !@gds_users.length.zero?
  end

  def create_gds_user
    admin_email = ENV['COGNITO_SEEDING_EMAIL'] || 'jakub.miarka+gdsadmin@digital.cabinet-office.gov.uk'
    add_user(
      email: admin_email,
      given_name: 'Jakub',
      family_name: 'Miarka',
      roles: [TEAMS::GDS],
    )
    add_user_to_group(username: admin_email, group: TEAMS::GDS)
  end

  def add_gds_users_to_group(gds_users = @gds_users)
    gds_users.each { |user|
      user_email = user.attributes.find { |att| att.name == 'email' }
      if user_email.value.end_with?(TEAMS::GDS_EMAIL_DOMAIN)
        Rails.logger.info("Adding user #{user.username} to the GDS group.")
        add_user_to_group(username: user.username, group: TEAMS::GDS)
      else
        Rails.logger.warn("Skipping user #{user.username} from being added GDS group - non-GDS email (#{user_email.value})")
      end
    }
  end

  def create_gds_group
    event = NewTeamEvent.create(name: TEAMS::GDS, team_type: 'other')
    Rails.logger.warn("There was an issue creating the GDS team: #{event.errors.full_messages}") unless event.valid?
  end
end
