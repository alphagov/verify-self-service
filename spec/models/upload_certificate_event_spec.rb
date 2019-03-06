require 'rails_helper'

RSpec.describe UploadCertificateEvent, type: :model do
  include_examples 'has data attributes', UploadCertificateEvent, [:usage, :value]
  include_examples 'is aggregated', UploadCertificateEvent, {usage: 'signing', value: 'bananananaanana'}
  include_examples 'is a creation event', UploadCertificateEvent, {usage: 'signing', value: 'bananananaanana'}

  context '#value' do
    it 'must be present' do
      event = UploadCertificateEvent.create()
      expect(event).to_not be_valid
      expect(event.errors[:value]).to eql ['can\'t be blank']
    end
  end

  context '#usage' do
    it 'must be present' do
      event = UploadCertificateEvent.create()
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to eql ['is not included in the list']
    end

    it 'must be signing or encryption' do
      event = UploadCertificateEvent.create(usage: 'foobar')
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to eql ['is not included in the list']
    end

    it 'happy when signing' do
      event = UploadCertificateEvent.create(usage: 'signing')
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to be_empty
    end

    it 'happy when encryption' do
      event = UploadCertificateEvent.create(usage: 'encryption')
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to be_empty
    end
  end

end
