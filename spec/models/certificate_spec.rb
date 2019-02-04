require 'rails_helper'

RSpec.describe Certificate, type: :model do
  it "is valid with valid attributes" do
    expect(Certificate.new(usage: 'Signing', value: 'Test')).to be_valid
  end

  it "is not valid without a cert type selection" do
    upload = Certificate.new(usage: nil)
    expect(upload).to_not be_valid
  end

  it "is not valid without a certificate upload" do
    upload = Certificate.new(value: nil)
    expect(upload).to_not be_valid
  end

end
