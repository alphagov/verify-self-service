module CertStatusNotifications
  MSA_SIGNING_TEMPLATE = 'db78c8a3-54c5-443a-ba93-b64c21799b4c'.freeze
  MSA_SIGNING_NO_DEADLINE_TEMPLATE = 'ib86fd33c-59c1-4ea4-b643-4a88756c21eb'.freeze
  MSA_VSP_DUAL_RUNNING_SP_ENCRYPTION_TEMPLATE = '3514d7ae-367f-428e-96d5-4eab3e09eeed'.freeze
  SP_ENCRYPTION_NO_DUAL_RUNNING_TEMPLATE = '2efd21a0-d3f9-4e35-a732-ff3a1c8f3f12'.freeze
  VSP_SP_SIGNING_TEMPLATE = '8342fbc4-a847-4587-932c-07065d471942'.freeze
  VSP_SP_SIGNING_NO_DEADLINE_TEMPLATE = 'a07ac619-de15-4bde-97cd-7c722f2b950b'.freeze

  def send_notification_email(mail_client:, certificate:, environment:, email_address:, deadline:)
    component = certificate.component
    is_dual_running = component.enabled_signing_certificates.length > 1

    template = choose_template(
      certificate: certificate,
      component_type: component.type,
      is_dual_running: is_dual_running,
      deadline: deadline,
    )

    personalisation =
      case template
      when MSA_SIGNING_TEMPLATE
        {
          team_name: component.team.name,
          environment: environment,
          time_and_date: deadline,
        }
      when MSA_SIGNING_NO_DEADLINE_TEMPLATE
        {
          team_name: component.team.name,
          environment: environment,
        }
      when MSA_VSP_DUAL_RUNNING_SP_ENCRYPTION_TEMPLATE
        {
          team_name: component.team.name,
          component: component.display_long_name,
          environment: environment,
        }
      when SP_ENCRYPTION_NO_DUAL_RUNNING_TEMPLATE
        {
          team_name: component.team.name,
          environment: environment,
        }
      when VSP_SP_SIGNING_TEMPLATE
        {
          team_name: component.team.name,
          component: component.display_long_name,
          environment: environment,
          time_and_date: deadline,
        }
      when VSP_SP_SIGNING_NO_DEADLINE_TEMPLATE
        {
          team_name: component.team.name,
          component: component.display_long_name,
          environment: environment,
        }
      end

    mail_client.send_email(
      email_address: email_address,
      template_id: template,
      personalisation: personalisation,
    )
  end

private

  def choose_template(certificate:, component_type:, is_dual_running:, deadline:)
    if certificate.signing?
      choose_template_for_signing_cert(component_type, deadline)
    elsif component_type == COMPONENT_TYPE::SP_SHORT && !is_dual_running
      SP_ENCRYPTION_NO_DUAL_RUNNING_TEMPLATE
    else
      MSA_VSP_DUAL_RUNNING_SP_ENCRYPTION_TEMPLATE
    end
  end

  def choose_template_for_signing_cert(component_type, deadline)
    if component_type == COMPONENT_TYPE::MSA_SHORT
      if defined?(deadline)
        MSA_SIGNING_TEMPLATE
      else
        MSA_SIGNING_NO_DEADLINE_TEMPLATE
      end
    elsif defined?(deadline)
      VSP_SP_SIGNING_TEMPLATE
    else
      VSP_SP_SIGNING_NO_DEADLINE_TEMPLATE
    end
  end
end
