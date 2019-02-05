require 'rails_helper'

RSpec.describe Certificate, type: :model do
  it "is valid with valid attributes" do
    expect(Certificate.new(usage: 'signing', value: 'Test')).to be_valid
    expect(Certificate.new(usage: 'encryption', value: 'Test')).to be_valid
  end

  it "is not valid with non-valid attributes" do
    expect(Certificate.new(usage: 'blah', value: 'Test')).to_not be_valid
  end

  it "is not valid without a usage and/or value" do
    expect(Certificate.new(usage: nil, value: 'Test')).to_not be_valid
    expect(Certificate.new(usage: 'signing', value: nil)).to_not be_valid
    expect(Certificate.new(usage: nil, value: nil)).to_not be_valid
  end
end
