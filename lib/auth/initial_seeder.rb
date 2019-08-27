class InitialSeeder
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
      SelfService.service(:cognito_client).get_group(
        group_name: TEAMS::GDS,
        user_pool_id: Rails.configuration.cognito_user_pool_id
      )
    rescue Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException
      Rails.logger.warn('The GDS group does not exist in Cognito!')
      return false
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.warn("Error occurred when checking GDS group: #{e}")
      return false
    end
    Rails.logger.info('The GDS group already exists in Cognito.')
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
      users = SelfService.service(:cognito_client).list_users(
        user_pool_id: Rails.configuration.cognito_user_pool_id,
        limit: 60
      )
      @gds_users = users.users.select { |user|
        user.attributes.find { |att|
          att.name == 'custom:roles' && att.value.include?(TEAMS::GDS)
        }
      }
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.error("Error occurred when looking for GDS users: #{e}")
      return false
    end
    Rails.logger.info("Found #{@gds_users.length} existing GDS users.")
    @gds_users.length
  end

  def create_gds_user
    admin_email = ENV['COGNITO_SEEDING_EMAIL'] || 'jakub.miarka+gdsadmin@digital.cabinet-office.gov.uk'
    SelfService.service(:cognito_client).admin_create_user(
      temporary_password: ENV['COGNITO_SEEDING_PASSWORD'] || 'abcDEF123%',
      user_attributes: [
        {
          name: 'email',
          value: admin_email
        },
        {
          name: 'given_name',
          value: 'Jakub'
        },
        {
          name: 'family_name',
          value: 'Miarka'
        },
        {
          name: 'custom:roles',
          value: TEAMS::GDS
        }
      ],
      username: admin_email,
      user_pool_id: Rails.configuration.cognito_user_pool_id
    )

    SelfService.service(:cognito_client).admin_add_user_to_group(
      user_pool_id: Rails.configuration.cognito_user_pool_id,
      username: admin_email,
      group_name: TEAMS::GDS
    )
  end

  def add_gds_users_to_group(gds_users = @gds_users)
    gds_users.each { |user|
      user_email = user.attributes.find { |att| att.name == 'email' }
      if user_email.value.end_with?(TEAMS::GDS_EMAIL_DOMAIN)
        Rails.logger.info("Adding user #{user.username} to the GDS group.")
        SelfService.service(:cognito_client).admin_add_user_to_group(
          user_pool_id: Rails.configuration.cognito_user_pool_id,
          username: user.username,
          group_name: TEAMS::GDS
        )
      else
        Rails.logger.warn("Skipping user #{user.username} from being added GDS group - non-GDS email (#{user_email.value})")
      end
    }
  end

  def create_gds_group
    event = NewTeamEvent.create(name: TEAMS::GDS)
    Rails.logger.warn("There was an issue creating the GDS team: #{event.errors.full_messages}") unless event.valid?
  end
end
