module CertStatusNotifications
  ENCRYPTION_TEMPLATE = '6626922e-3eb7-45e3-b8a9-989ba32a9178'.freeze
  MSA_SIGNING_TEMPLATE = 'db78c8a3-54c5-443a-ba93-b64c21799b4c'.freeze
  MSA_SIGNING_NO_DEADLINE_TEMPLATE = 'ib86fd33c-59c1-4ea4-b643-4a88756c21eb'.freeze
  VSP_SP_SIGNING_TEMPLATE = '8342fbc4-a847-4587-932c-07065d471942'.freeze
  VSP_SP_SIGNING_NO_DEADLINE_TEMPLATE = 'a07ac619-de15-4bde-97cd-7c722f2b950b'.freeze
  attr_accessor :personalisation

  def send_notification_email(mail_client:, certificate:, email_address:)
    component = certificate.component
    second_signing_certificate = component.enabled_signing_certificates.second

    @personalisation = {
      team_name: component.team.name,
      component: component.display_long_name,
      environment: component.environment,
    }

    template = choose_template(
      certificate: certificate,
      component_type: component.type,
      deadline: second_signing_certificate,
    )

    mail_client.send_email(
      email_address: email_address,
      template_id: template,
      personalisation: @personalisation,
    )
  end

private

  def choose_template(certificate:, component_type:, deadline:)
    return ENCRYPTION_TEMPLATE unless certificate.signing?

    if component_type == COMPONENT_TYPE::MSA_SHORT
      return MSA_SIGNING_NO_DEADLINE_TEMPLATE unless deadline.present?

      @personalisation.merge!(time_and_date: deadline.x509.not_after)
      MSA_SIGNING_TEMPLATE
    else
      return VSP_SP_SIGNING_NO_DEADLINE_TEMPLATE unless deadline.present?

      @personalisation.merge!(time_and_date: deadline.x509.not_after)
      VSP_SP_SIGNING_TEMPLATE
    end
  end
end
