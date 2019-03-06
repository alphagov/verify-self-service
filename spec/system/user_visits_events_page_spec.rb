require 'rails_helper'

RSpec.describe 'the events page', type: :system do
  it 'there are some events' do
    UploadCertificateEvent.create(usage: 'signing', value: 'foobar')
    UploadCertificateEvent.create(usage: 'signing', value: 'barfoo')
    UploadCertificateEvent.create(usage: 'signing', value: 'foobarbaz')
    visit events_path
    expect(page).to have_content 'foobar'
    expect(page).to have_content 'barfoo'
    expect(page).to have_content 'foobarbaz'
  end

  it 'is paginated' do
    events = 55.times.map do |idx|
      UploadCertificateEvent.create(usage: 'signing', value: "foobar#{idx}foobar")
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
