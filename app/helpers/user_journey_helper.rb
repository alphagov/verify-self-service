module UserJourneyHelper
  def primary_signing_certificate?(certificate)
    certificate == certificate.component.enabled_signing_certificates.first
  end

  def secondary_signing_certificate?(certificate)
    certificate == certificate.component.enabled_signing_certificates.second
  end

  def deployment_in_progress?(certificate)
    certificate.component.enabled_signing_certificates.first.deploying?
  end

  def position(certificate)
    primary_signing_certificate?(certificate) ? 'primary' : 'secondary'
  end

  def certificate_status(certificate)
    if certificate.nil?
      "MISSING"
    elsif certificate.expired?
      "EXPIRED"
    elsif certificate.expires_soon?
      expiry_label(certificate)
    elsif certificate.deploying?
      "DEPLOYING"
    else
      "IN USE"
    end
  end

  def certificate_status_tag_class(certificate)
    return 'app-certificate-tag-deploying' if certificate.deploying?
    return 'app-certificate-tag-expired' if certificate.expired?
    return 'app-certificate-tag-expiring' if certificate.expires_soon?
  end

  def expiry_label(certificate)
    if certificate.days_left > 1
      "EXPIRES IN #{certificate.days_left.to_i} DAYS"
    elsif certificate.days_left == 1 && certificate.hours_left > 23
      "EXPIRES IN #{certificate.days_left.to_i} DAY"
    elsif certificate.hours_left > 1 && certificate.minutes_left > 59
      "EXPIRES IN #{certificate.hours_left} HOURS"
    else
      "EXPIRES IN #{certificate.minutes_left} MINUTES"
    end
  end

  def certificate_expiry_count(components)
    components.map(&:current_certificates).flatten.select(&:expires_soon?).count
  end

  def idp_team_user?
    Team.find(current_user.team).team_type == TEAMS::IDP unless current_user.team.nil?
  end

  def rp_team_user?
    Team.find(current_user.team).team_type == TEAMS::RP unless current_user.team.nil?
  end
end
