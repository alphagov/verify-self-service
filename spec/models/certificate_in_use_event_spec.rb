require 'rails_helper'
RSpec.describe CertificateInUseEvent, type: :model do
  include NotifySupport, CognitoSupport
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
  it 'is valid and persisted with hub_use_confirmation_at not nil' do
    stub_notify_response
    certificate = create(:sp_signing_certificate)
    expect(certificate.in_use_at).to be_nil
    certificate_in_use_event = create(:certificate_in_use_event, certificate: certificate)
    expect(certificate_in_use_event).to be_valid
    expect(certificate_in_use_event).to be_persisted
    expect(certificate.in_use_at).not_to be_nil
  end
  it 'emails notification with a template having defined deadline when msa signing certificate is uploaded' do
    stub_notify_response
    msa_component = create(:msa_component)
    old_signing_certificate = create(:upload_certificate_event, component: msa_component).certificate
    stub_cognito_response(method: :list_users_in_group, payload: cognito_users)

    expect(subject.class).to receive(:create).with(any_args).and_call_original.at_least(:once)
    certificate = create(:upload_certificate_event, component: msa_component).certificate
    component = certificate.component

    expected_body = {
      email_address: 'test@test.com',
      template_id: 'db78c8a3-54c5-443a-ba93-b64c21799b4c',
      personalisation: {
        team_name: component.team.name,
        component: component.display_long_name,
        environment: component.environment,
        time_and_date: component.enabled_signing_certificates.second.x509.not_after,
      }
    }
    expect(expected_body[:personalisation][:time_and_date]).to be_present
    expect(stub_notify_request(expected_body)).to have_been_made.once
    expect(certificate.events.map(&:class)).to eq [UploadCertificateEvent, CertificateInUseEvent, CertificateNotificationSentEvent]
  end
  it 'emails notification with a template having defined deadline when sp signing certificate is uploaded' do
    old_signing_certificate = create(:upload_certificate_event).certificate
    stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    stub_notify_response

    expect(subject.class).to receive(:create).with(any_args).and_call_original.at_least(:once)
    create(:assign_sp_component_to_service_event, sp_component_id: old_signing_certificate.component.id)
    certificate = create(:upload_certificate_event, component: old_signing_certificate.component).certificate
    component = certificate.component

    expected_body = {
      email_address: 'test@test.com',
      template_id: '8342fbc4-a847-4587-932c-07065d471942',
      personalisation: {
        team_name: component.team.name,
        component: component.display_long_name,
        environment: component.environment,
        time_and_date: component.enabled_signing_certificates.second.x509.not_after,
      }
    }
    expect(expected_body[:personalisation][:time_and_date]).to be_present
    expect(stub_notify_request(expected_body)).to have_been_made.once
    expect(certificate.events.map(&:class)).to eq [UploadCertificateEvent, CertificateInUseEvent, CertificateNotificationSentEvent]
  end
  it 'emails notification with a template without defined deadline when msa signing certificate is uploaded' do
    stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    stub_notify_response

    expect(subject.class).to receive(:create).with(any_args).and_call_original.at_least(:once)
    certificate = create(:upload_certificate_event, component: create(:msa_component)).certificate
    component = certificate.component

    expected_body = {
      email_address: 'test@test.com',
      template_id: 'ib86fd33c-59c1-4ea4-b643-4a88756c21eb',
      personalisation: {
        team_name: component.team.name,
        component: component.display_long_name,
        environment: component.environment,
      }
    }

    expect(stub_notify_request(expected_body)).to have_been_made.once
    expect(certificate.events.map(&:class)).to eq [UploadCertificateEvent, CertificateInUseEvent, CertificateNotificationSentEvent]
  end
  it 'emails notification with a template without defined deadline when sp signing certificate is uploaded' do
    stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    stub_notify_response

    expect(subject.class).to receive(:create).with(any_args).and_call_original.at_least(:once)
    sp_component = create(:sp_component)
    create(:assign_sp_component_to_service_event, sp_component_id: sp_component.id)
    certificate = create(:upload_certificate_event, component: sp_component).certificate
    component = certificate.component

    expected_body = {
      email_address: 'test@test.com',
      template_id: 'a07ac619-de15-4bde-97cd-7c722f2b950b',
      personalisation: {
        team_name: component.team.name,
        component: component.display_long_name,
        environment: component.environment,
      }
    }

    expect(stub_notify_request(expected_body)).to have_been_made.once
    expect(certificate.events.map(&:class)).to eq [UploadCertificateEvent, CertificateInUseEvent, CertificateNotificationSentEvent]
  end
  it 'emails notification with encryption template when msa encryption certificate is replaced' do
    stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    stub_notify_response
    msa_encryption_certificate = create(:msa_encryption_certificate)

    expect(subject.class).to receive(:create).with(any_args).and_call_original.at_least(:once)
    event = create(:replace_encryption_certificate_event, encryption_certificate_id: msa_encryption_certificate.id, component: msa_encryption_certificate.component)
    component = event.component
    certificate = component.encryption_certificate

    expected_body = {
      email_address: 'test@test.com',
      template_id: '6626922e-3eb7-45e3-b8a9-989ba32a9178',
      personalisation: {
        team_name: component.team.name,
        component: component.display_long_name,
        environment: component.environment,
      }
    }
    expect(stub_notify_request(expected_body)).to have_been_made.once
    expect(certificate.events.map(&:class)).to eq [CertificateInUseEvent, CertificateNotificationSentEvent]
  end
  it 'emails notification with encryption template when sp encryption certificate is replaced' do
    stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    stub_notify_response
    sp_encryption_certificate = create(:sp_encryption_certificate)

    create(:assign_sp_component_to_service_event, sp_component_id: sp_encryption_certificate.component.id)
    expect(subject.class).to receive(:create).with(any_args).and_call_original.at_least(:once)
    event = create(:replace_encryption_certificate_event, encryption_certificate_id: sp_encryption_certificate.id, component: sp_encryption_certificate.component)
    component = event.component
    certificate = component.encryption_certificate
    expected_body = {
      email_address: 'test@test.com',
      template_id: '6626922e-3eb7-45e3-b8a9-989ba32a9178',
      personalisation: {
        team_name: component.team.name,
        component: component.display_long_name,
        environment: component.environment,
      }
    }
    expect(stub_notify_request(expected_body)).to have_been_made.once
    expect(certificate.events.map(&:class)).to eq [CertificateInUseEvent, CertificateNotificationSentEvent]
  end
  it 'emails notification sent to 3 team members when certificate is replaced' do
    stub_cognito_response(method: :list_users_in_group, payload: many_cognito_users)
    stub_notify_response
    sp_encryption_certificate = create(:sp_encryption_certificate)

    create(:assign_sp_component_to_service_event, sp_component_id: sp_encryption_certificate.component.id)
    expect(subject.class).to receive(:create).with(any_args).and_call_original.at_least(:once)
    event = create(:replace_encryption_certificate_event, encryption_certificate_id: sp_encryption_certificate.id, component: sp_encryption_certificate.component)
    component = event.component
    certificate = component.encryption_certificate
    expected_body = {
      email_address: 'test@test.com',
      template_id: '6626922e-3eb7-45e3-b8a9-989ba32a9178',
      personalisation: {
        team_name: component.team.name,
        component: component.display_long_name,
        environment: component.environment,
      }
    }
    expect(stub_notify_request(expected_body)).to have_been_made.times(3)
    expect(certificate.events.map(&:class)).to eq [CertificateInUseEvent, CertificateNotificationSentEvent]
  end
  it 'logs error when mail client is return 404' do
    stub_notify_error_response
    stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    sp_encryption_certificate = create(:sp_encryption_certificate)
    create(:assign_sp_component_to_service_event, sp_component_id: sp_encryption_certificate.component.id)

    expect(subject.class).to receive(:create).with(any_args).and_call_original.at_least(:once)
    expect(Rails.logger).to receive(:error).with(any_args).and_call_original.at_least(:once)

    event = create(:replace_encryption_certificate_event, encryption_certificate_id: sp_encryption_certificate.id, component: sp_encryption_certificate.component)
    component = event.component
    certificate = component.encryption_certificate

    expected_body = {
      email_address: 'test@test.com',
      template_id: '6626922e-3eb7-45e3-b8a9-989ba32a9178',
      personalisation: {
        team_name: component.team.name,
        component: component.display_long_name,
        environment: component.environment,
      }
    }
    expect(stub_notify_request(expected_body)).to have_been_made.once
  end
end
