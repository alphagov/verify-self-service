require 'notify/notification'
require 'auth/authentication_backend'

module CertificateExpiryReminder
  class Check
    include Notification
    include AuthenticationBackend

    REMIND_DAYS_LEFT = [30, 7, 3].freeze

    def run
      Rails.logger.info("Looking for expiring certs which are enabled...")
      certificates = expiring_certs
      Rails.logger.info("Found #{certificates.count} expiring certs.")
      if certificates.any?
        send_notifications(group_by_team(certificates))
      end
    end

    def force_run(date)
      Rails.logger.info("[FORCE for #{date}] Looking for expiring certs which are enabled...")
      certificates = expiring_certs_for_date(date)
      Rails.logger.info("[FORCE for #{date}] Found #{certificates.count} expiring certs.")
      if certificates.any?
        send_notifications(group_by_team(certificates))
      end
    end

  private

    def expiring_certs
      Certificate.where('enabled = ?', true).select { |c| REMIND_DAYS_LEFT.include?(c.days_left) && c.component.present? }
    end

    def expiring_certs_for_date(date)
      day_diff = (Time.now.to_date - date.to_date).to_i
      adjusted_remind_days_left = REMIND_DAYS_LEFT.map { |day| day - day_diff }
      Certificate.where('enabled = ?', true).select { |c| adjusted_remind_days_left.include?(c.days_left) && c.component.present? }
    end

    def group_by_team(certificates)
      certificates.group_by { |c| c.component.team_id }
    end

    def send_notifications(team_certificates)
      team_certificates.each do |team_id, certificates|
        team = Team.find_by_id(team_id)
        certs_by_days_left = certificates.group_by(&:days_left)
        certs_by_days_left.each do |days, certs|
          send_reminder(team, certs, days)
        end
      end
    end

    def send_reminder(team, certs, days)
      recipients = team_recipients(team.team_alias)
      certificates = certs.sort_by { |cert| [cert.component.environment, cert.component_type] }.reverse
      certificates_list = certificates.map do |cert|
        "#{cert.component.display_long_name} (#{cert.component.environment}): #{cert.usage} certificate - expires on #{cert.x509.not_after}"
      end
      Rails.logger.info("Sending a #{days}-day reminder email to #{team.name} team (#{recipients.count} recipients, #{certificates_list.count} certificates)")
      Rails.logger.error("No recipients found for #{team.name}!") if recipients.empty?
      recipients.each do |email|
        send_reminder_email(
          email_address: email,
          team_name: team.name,
          days_left: days,
          certificates: certificates_list,
        )
      end
    end

    def team_recipients(team_alias)
      users = get_users_in_group(group_name: team_alias)
      users.map { |user| user.attributes.find { |att| att.name == 'email' }.value }
    end
  end
end
