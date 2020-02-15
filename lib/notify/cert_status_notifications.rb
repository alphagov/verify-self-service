module CertStatusNotifications
  MSA_ENCRYPTION_TEMPLATE = '191168a4-1add-4183-8d0d-717eecc42303'.freeze
  MSA_SIGNING_TEMPLATE = 'db78c8a3-54c5-443a-ba93-b64c21799b4c'.freeze
  MSA_SIGNING_NO_DEADLINE_TEMPLATE = 'ib86fd33c-59c1-4ea4-b643-4a88756c21eb'.freeze
  VSP_SP_ENCRYPTION_TEMPLATE = '8fa0bb83-7471-4d8e-8816-56d60ee7e32a'.freeze
  VSP_SP_SIGNING_TEMPLATE = '8342fbc4-a847-4587-932c-07065d471942'.freeze
  VSP_SP_SIGNING_NO_DEADLINE_TEMPLATE = 'a07ac619-de15-4bde-97cd-7c722f2b950b'.freeze
  attr_accessor :personalisation

  def send_notification_email(mail_client:, certificate:, email_address:)
    component = certificate.component

    @personalisation = {
      team_name: component.team.name,
      component: component.display_long_name,
      environment: component.environment,
    }

    template = choose_template(
      certificate: certificate,
      component_type: component.type,
      deadline: component.enabled_signing_certificates.second,
    )

    mail_client.send_email(
      email_address: email_address,
      template_id: template,
      personalisation: @personalisation,
    )
  end

private

  def choose_template(certificate:, component_type:, deadline:)
    if certificate.signing?
      choose_signing_template(component_type, deadline)
    else
      choose_encryption_template(component_type)
    end
  end

  def choose_signing_template(component_type, deadline)
    if component_type == COMPONENT_TYPE::MSA_SHORT && deadline
      apply_deadline_on(template: MSA_SIGNING_TEMPLATE, deadline: deadline.x509.not_after)
    elsif component_type == COMPONENT_TYPE::MSA_SHORT && !deadline
      MSA_SIGNING_NO_DEADLINE_TEMPLATE
    elsif component_type != COMPONENT_TYPE::MSA_SHORT && deadline
      apply_deadline_on(template: VSP_SP_SIGNING_TEMPLATE, deadline: deadline.x509.not_after)
    else
      VSP_SP_SIGNING_NO_DEADLINE_TEMPLATE
    end
  end

  def choose_encryption_template(component_type)
    return MSA_ENCRYPTION_TEMPLATE if component_type == COMPONENT_TYPE::MSA_SHORT

    VSP_SP_ENCRYPTION_TEMPLATE
  end

  def apply_deadline_on(template:, deadline:)
    @personalisation.merge!(time_and_date: deadline)
    template
  end
end
