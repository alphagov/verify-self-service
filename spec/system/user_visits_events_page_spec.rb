require 'rails_helper'

include CertificateSupport

RSpec.describe 'the events page', type: :system do



  it 'there are some events' do

    root = PKI.new
    good_cert_1 = root.sign(generate_cert_with_expiry(Time.now + 2.months))
    good_cert_value_1 = Base64.strict_encode64(good_cert_1.to_der)
    good_cert_2 = root.sign(generate_cert_with_expiry(Time.now + 2.months))
    good_cert_value_2 = Base64.strict_encode64(good_cert_2.to_der)
    good_cert_3 = root.sign(generate_cert_with_expiry(Time.now + 2.months))
    good_cert_value_3 = Base64.strict_encode64(good_cert_3.to_der)

    UploadCertificateEvent.create(usage: 'signing', value: good_cert_value_1)
    UploadCertificateEvent.create(usage: 'signing', value: good_cert_value_2)
    UploadCertificateEvent.create(usage: 'signing', value: good_cert_value_3)
    visit events_path
    expect(page).to have_content good_cert_value_1
    expect(page).to have_content good_cert_value_2
    expect(page).to have_content good_cert_value_3
  end

  it 'is paginated' do

    root = PKI.new

    events = 55.times.map do
      UploadCertificateEvent.create(usage: 'signing', value: Base64.strict_encode64(root.sign(generate_cert_with_expiry(Time.now + 2.months)).to_der))
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
