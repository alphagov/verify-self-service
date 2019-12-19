require 'rails_helper'

RSpec.describe CertificateExpiryReminder, type: :model do
  include CognitoSupport, NotifySupport

  let(:certificate_expiry_reminder) { subject::Check.new() }
  let(:email) { 'test@test.com' }
  let(:cognito_users) {
    { users: [
        { username: '0000',
         attributes: [{name: "given_name", value: "Cherry"},
                      {name: "family_name", value: "One"},
                      {name: "email", value: email},
                      {name: "custom:roles", value: "certmgr"}
         ]}
    ]}
  }
  let(:many_cognito_users) {
    { users: [
        { username: '0000',
         attributes: [{name: "given_name", value: "Cherry"},
                      {name: "family_name", value: "One"},
                      {name: "email", value: email},
                      {name: "custom:roles", value: "certmgr"}
        ]},
        { username: '0001',
          attributes: [{name: "given_name", value: "Cherry"},
                       {name: "family_name", value: "Two"},
                       {name: "email", value: email},
                       {name: "custom:roles", value: "certmgr"}
        ]},
        { username: '0002',
            attributes: [{name: "given_name", value: "Cherry"},
                         {name: "family_name", value: "Three"},
                         {name: "email", value: email},
                         {name: "custom:roles", value: "certmgr"}
        ]}
    ]}
  }

  context 'when scheduled' do
    it 'sends email if certificate is expiring in 30 days' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
      stub_notify_response

      expires_in_days = 30
      cert = create(:vsp_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days))
      create(:replace_encryption_certificate_event,
        component: cert.component,
        encryption_certificate_id: cert.id,
        admin_upload: true,
      )

      certificate_expiry_reminder.run

      expected_expiry_date = (Time.now + expires_in_days.days).strftime("%d %B %Y")
      expected_call = {
        email_address: email,
        template_id: "bbc34127-7fca-4d78-a95b-703da58e15ce",
        personalisation: {
          subject: "Your GOV.UK Verify certificates will expire on #{expected_expiry_date}",
          team: cert.component.team.name,
          no_of_certs: 1,
          multiple: 'no',
          expire_on: expected_expiry_date,
          certificates: ["Verify Service Provider (staging): encryption certificate - expires on #{cert.x509.not_after}"],
          url: "http://www.test.com"
        }
      }

      expect(stub_notify_request(expected_call)).to have_been_made.once
    end

    it 'sends email if certificate is expiring in 7 days' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
      stub_notify_response

      expires_in_days = 7
      cert = create(:vsp_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days))
      create(:replace_encryption_certificate_event,
        component: cert.component,
        encryption_certificate_id: cert.id,
        admin_upload: true,
      )

      certificate_expiry_reminder.run

      expected_expiry_date = (Time.now + expires_in_days.days).strftime("%d %B %Y")
      expected_call = {
        email_address: email,
        template_id: "bbc34127-7fca-4d78-a95b-703da58e15ce",
        personalisation: {
          subject: "Your GOV.UK Verify certificates will expire on #{expected_expiry_date}",
          team: cert.component.team.name,
          no_of_certs: 1,
          multiple: 'no',
          expire_on: expected_expiry_date,
          certificates: ["Verify Service Provider (staging): encryption certificate - expires on #{cert.x509.not_after}"],
          url: "http://www.test.com"
        }
      }

      expect(stub_notify_request(expected_call)).to have_been_made.once
    end

    it 'sends emails if certificate is expiring in 7 days and team have many members' do
      stub_cognito_response(method: :list_users_in_group, payload: many_cognito_users)
      stub_notify_response

      expires_in_days = 7
      cert = create(:vsp_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days))
      create(:replace_encryption_certificate_event,
        component: cert.component,
        encryption_certificate_id: cert.id,
        admin_upload: true,
      )
      
      certificate_expiry_reminder.run

      expected_expiry_date = (Time.now + expires_in_days.days).strftime("%d %B %Y")
      expected_call = {
        email_address: email,
        template_id: "bbc34127-7fca-4d78-a95b-703da58e15ce",
        personalisation: {
          subject: "Your GOV.UK Verify certificates will expire on #{expected_expiry_date}",
          team: cert.component.team.name,
          no_of_certs: 1,
          multiple: 'no',
          expire_on: expected_expiry_date,
          certificates: ["Verify Service Provider (staging): encryption certificate - expires on #{cert.x509.not_after}"],
          url: "http://www.test.com"
        }
      }

      expect(stub_notify_request(expected_call)).to have_been_made.times(3)
    end

    it 'sends emails if certificate is expiring in 7 days and team have many members and many certs' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
      stub_notify_response

      expires_in_days = 7
      
      team = create(:team)

      component_vsp = create(:sp_component, vsp: true, environment: 'production', team_id: team.id)
      vsp_cert_one = create(:vsp_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days), component: component_vsp)
      create(:replace_encryption_certificate_event,
        component: vsp_cert_one.component,
        encryption_certificate_id: vsp_cert_one.id,
        admin_upload: true,
      )
      vsp_cert_two = create(:vsp_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days), component: component_vsp)

      component_msa = create(:msa_component, environment: 'integration', team_id: team.id)
      msa_cert_one = create(:msa_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days), component: component_msa)
      create(:replace_encryption_certificate_event,
        component: msa_cert_one.component,
        encryption_certificate_id: msa_cert_one.id,
        admin_upload: true,
      )
      msa_cert_two = create(:msa_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days), component: component_msa)
      certificate_expiry_reminder.run

      expected_expiry_date = (Time.now + expires_in_days.days).strftime("%d %B %Y")
      expected_call = {
        email_address: email,
        template_id: "bbc34127-7fca-4d78-a95b-703da58e15ce",
        personalisation: {
          subject: "Your GOV.UK Verify certificates will expire on #{expected_expiry_date}",
          team: component_vsp.team.name,
          no_of_certs: 4,
          multiple: 'yes',
          expire_on: expected_expiry_date,
          certificates: [
            "Verify Service Provider (production): signing certificate - expires on #{vsp_cert_two.x509.not_after}",
            "Verify Service Provider (production): encryption certificate - expires on #{vsp_cert_one.x509.not_after}",
            "Matching Service Adapter (integration): signing certificate - expires on #{msa_cert_two.x509.not_after}",
            "Matching Service Adapter (integration): encryption certificate - expires on #{msa_cert_one.x509.not_after}"
          ],
          url: "http://www.test.com"
        }
      }

      expect(stub_notify_request(expected_call)).to have_been_made.once
    end

    it 'sends email if certificate is expiring in 3 days' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
      stub_notify_response

      expires_in_days = 3
      cert = create(:vsp_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days))
      create(:replace_encryption_certificate_event,
        component: cert.component,
        encryption_certificate_id: cert.id,
        admin_upload: true,
      )
      certificate_expiry_reminder.run

      expected_expiry_date = (Time.now + expires_in_days.days).strftime("%d %B %Y")
      expected_call = {
        email_address: email,
        template_id: "bbc34127-7fca-4d78-a95b-703da58e15ce",
        personalisation: {
          subject: "Urgent: your GOV.UK Verify certificates will expire on #{expected_expiry_date}",
          team: cert.component.team.name,
          no_of_certs: 1,
          multiple: 'no',
          expire_on: expected_expiry_date,
          certificates: ["Verify Service Provider (staging): encryption certificate - expires on #{cert.x509.not_after}"],
          url: "http://www.test.com"
        }
      }

      expect(stub_notify_request(expected_call)).to have_been_made.once
    end

    it 'does not send email if an encryption certificate is expiring in 3 days but is not active on a component' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
      stub_notify_response

      expires_in_days = 3
      cert = create(:vsp_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days))

      certificate_expiry_reminder.run

      expected_expiry_date = (Time.now + expires_in_days.days).strftime("%d %B %Y")
      expected_call = {
        email_address: email,
        template_id: "bbc34127-7fca-4d78-a95b-703da58e15ce",
        personalisation: {
          subject: "Urgent: your GOV.UK Verify certificates will expire on #{expected_expiry_date}",
          team: cert.component.team.name,
          no_of_certs: 1,
          multiple: 'no',
          expire_on: expected_expiry_date,
          certificates: ["Verify Service Provider (staging): encryption certificate - expires on #{cert.x509.not_after}"],
          url: "http://www.test.com"
        }
      }

      expect(stub_notify_request(expected_call)).not_to have_been_made
    end

    it 'does not send email if no certificate is expiring' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
      stub_notify_response

      expires_in_days = 180
      cert = create(:vsp_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days))
      certificate_expiry_reminder.run

      expected_expiry_date = (Time.now + expires_in_days.days).strftime("%d %B %Y")
      expected_call = {
        email_address: email,
        template_id: "bbc34127-7fca-4d78-a95b-703da58e15ce",
        personalisation: {
          subject: "Your GOV.UK Verify certificates will expire on #{expected_expiry_date}",
          team: cert.component.team.name,
          no_of_certs: 1,
          multiple: 'no',
          expire_on: expected_expiry_date,
          certificates: ["Verify Service Provider (staging): encryption certificate - expires on #{cert.x509.not_after}"],
          url: "http://www.test.com"
        }
      }

      expect(stub_notify_request(expected_call)).not_to have_been_made.once
    end

    it 'does not send email if a certificate is expiring in 22 days' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
      stub_notify_response

      expires_in_days = 22
      cert = create(:vsp_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days))
      certificate_expiry_reminder.run

      expected_expiry_date = (Time.now + expires_in_days.days).strftime("%d %B %Y")
      expected_call = {
        email_address: email,
        template_id: "bbc34127-7fca-4d78-a95b-703da58e15ce",
        personalisation: {
          subject: "Your GOV.UK Verify certificates will expire on #{expected_expiry_date}",
          team: cert.component.team.name,
          no_of_certs: 1,
          multiple: 'no',
          expire_on: expected_expiry_date,
          certificates: ["Verify Service Provider (staging): encryption certificate - expires on #{cert.x509.not_after}"],
          url: "http://www.test.com"
        }
      }

      expect(stub_notify_request(expected_call)).not_to have_been_made.once
    end
  end

  context 'when forced/manually ran' do
    it 'sends email if a certificate is expiring in 29 days but reminder is ran for yesterday' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
      stub_notify_response

      expires_in_days = 29
      cert = create(:vsp_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days))
      create(:replace_encryption_certificate_event,
        component: cert.component,
        encryption_certificate_id: cert.id,
        admin_upload: true,
      )

      certificate_expiry_reminder.force_run(Time.now - 1.day)

      expected_expiry_date = (Time.now + expires_in_days.days).strftime("%d %B %Y")
      expected_call = {
        email_address: email,
        template_id: "bbc34127-7fca-4d78-a95b-703da58e15ce",
        personalisation: {
          subject: "Your GOV.UK Verify certificates will expire on #{expected_expiry_date}",
          team: cert.component.team.name,
          no_of_certs: 1,
          multiple: 'no',
          expire_on: expected_expiry_date,
          certificates: ["Verify Service Provider (staging): encryption certificate - expires on #{cert.x509.not_after}"],
          url: "http://www.test.com"
        }
      }

      expect(stub_notify_request(expected_call)).to have_been_made.once
    end

    it 'does not send email if a certificate is expiring in 25 days and reminder is ran for yesterday' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
      stub_notify_response

      expires_in_days = 25
      cert = create(:vsp_encryption_certificate, value: PKI.new.generate_encoded_cert(expires_in: expires_in_days.days))
      certificate_expiry_reminder.force_run(Time.now - 1.day)

      expected_expiry_date = (Time.now + expires_in_days.days).strftime("%d %B %Y")
      expected_call = {
        email_address: email,
        template_id: "bbc34127-7fca-4d78-a95b-703da58e15ce",
        personalisation: {
          subject: "Your GOV.UK Verify certificates will expire on #{expected_expiry_date}",
          team: cert.component.team.name,
          no_of_certs: 1,
          multiple: 'no',
          expire_on: expected_expiry_date,
          certificates: ["Verify Service Provider (staging): encryption certificate - expires on #{cert.x509.not_after}"],
          url: "http://www.test.com"
        }
      }

      expect(stub_notify_request(expected_call)).not_to have_been_made.once
    end
  end
end
