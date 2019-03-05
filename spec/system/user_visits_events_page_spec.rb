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
end
