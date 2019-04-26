require 'rails_helper'
require 'auth_test_helper'

RSpec.describe 'New Component Page', type: :system do

  before(:each) do
    stub_auth
  end

  component_name = 'test component'
  component_params = {component_type: 'MSA', name: component_name}

  let(:component) { NewComponentEvent.create(component_params).component }

  let(:upload_certs) do
        root = PKI.new
        x509_cert_1 = root.generate_encoded_cert(expires_in: 2.months)
        x509_cert_2 = root.generate_encoded_cert(expires_in: 9.months)
        UploadCertificateEvent.create({usage: "signing", value: x509_cert_1, component_id: component.id}).certificate
        UploadCertificateEvent.create({usage: "signing", value: x509_cert_2, component_id: component.id}).certificate
  end


  it 'successfully creates a new component' do
    visit component_path(component.id)

    expect(page).to have_selector('h1', text: component_name)
    expect(page).to have_link 'Upload'
  end

  it 'shows list of enabled signing certificates' do
    upload_certs
    certs = component.certificates
    visit component_path(component.id)
    expect(page).to have_selector("#edit_certificate_#{certs[0].id}")
    expect(page).to have_selector("#edit_certificate_#{certs[1].id}")
  end

  it 'successfully disables a certificate' do
    upload_certs
    certs = component.enabled_signing_certificates
    visit component_path(component.id)
    expect(page).to have_selector("#certificate_table_#{certs[0].id}")
    button_element = page.find(:css, "#edit_certificate_#{certs[0].id} > input[name='commit']")
    button_element.click

    expect(page).to have_selector('h1', text: component_name)
    expect(page).to have_selector("#edit_certificate_#{certs[0].id}")
    expect(page).to have_selector("#edit_certificate_#{certs[1].id}")
    expect(page).to have_selector("#certificate_table_#{certs[0].id} > td:nth-child(4)", text: "false")

  end

  it 'shows list of disabled certificates' do
    upload_certs
    certs = component.enabled_signing_certificates
    visit component_path(component.id)
    button_element = page.find(:css, "#edit_certificate_#{certs[0].id} > input[name='commit']")
    button_element.click
    button_element = page.find(:css, "#edit_certificate_#{certs[1].id} > input[name='commit']")
    button_element.click

    disabled_certs = component.disabled_signing_certificates

    expect(page).to have_selector('h1', text: component_name)
    expect(page).to have_selector("#certificate_table_#{disabled_certs[0].id} > td:nth-child(4)", text: "false")
    expect(page).to have_selector("#certificate_table_#{disabled_certs[1].id} > td:nth-child(4)", text: "false")

  end

  it 'successfully enables a certificate' do
    upload_certs
    certs = component.enabled_signing_certificates
    visit component_path(component.id)
    button_element = page.find(:css, "#edit_certificate_#{certs[0].id} > input[name='commit']")
    button_element.click
    button_element = page.find(:css, "#edit_certificate_#{certs[1].id} > input[name='commit']")
    button_element.click

    disabled_certs = component.disabled_signing_certificates

    expect(page).to have_selector("#certificate_table_#{disabled_certs[0].id}")
    button_element = page.find(:css, "#edit_certificate_#{disabled_certs[0].id} > input[name='commit']")
    button_element.click

    expect(page).to have_selector('h1', text: component_name)
    expect(page).to have_selector("#certificate_table_#{disabled_certs[0].id} > td:nth-child(4)", text: "true")

  end

end
