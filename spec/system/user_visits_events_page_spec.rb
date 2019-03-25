require 'rails_helper'
require 'auth_test_helper'

include CertificateSupport

RSpec.describe 'the events page', type: :system do

  before(:each) do
    stub_auth
  end

  component_params = { component_type: 'MSA', name:'fake_name' }
  let(:component) { NewComponentEvent.create(component_params).component }
  let(:root) { PKI.new }

  it 'there are some events' do
    good_cert_1 = root.generate_encoded_cert(expires_in: 2.months)
    good_cert_2 = root.generate_encoded_cert(expires_in: 2.months)
    good_cert_3 = root.generate_encoded_cert(expires_in: 2.months)

    UploadCertificateEvent.create(usage: 'signing', value: good_cert_1, component_id: component.id)
    UploadCertificateEvent.create(usage: 'signing', value: good_cert_2, component_id: component.id)
    UploadCertificateEvent.create(usage: 'signing', value: good_cert_3, component_id: component.id)

    visit events_path
    expect(page).to have_content good_cert_1
    expect(page).to have_content good_cert_2
    expect(page).to have_content good_cert_3
  end

  it 'is paginated' do
    events = 55.times.map do
      UploadCertificateEvent.create(usage: 'signing', value: root.generate_encoded_cert(expires_in: 2.months), component_id: component.id)
    end.reverse

    visit events_path
    expect(page).to have_selector('tbody tr', count: 25)
    first_page_events = events.slice!(0, 25)
    second_page_events = events.slice!(0, 25)
    third_page_events = events.slice!(0, 25)
    first_page_events.each do |event|
      expect(page).to have_content event.value
    end
    (second_page_events + third_page_events).each do |event|
      expect(page).to_not have_content event.value
    end
    click_on 'Next ›'
    second_page_events.each do |event|
      expect(page).to have_content event.value
    end
    (first_page_events + third_page_events).each do |event|
      expect(page).to_not have_content event.value
    end
    click_on 'Next ›'
    third_page_events.each do |event|
      expect(page).to have_content event.value
    end
    (first_page_events + second_page_events).each do |event|
      expect(page).to_not have_content event.value
    end
  end
end
