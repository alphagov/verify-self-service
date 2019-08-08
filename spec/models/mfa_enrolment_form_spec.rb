require 'rails_helper'

RSpec.describe MfaEnrolmentForm, type: :model do

  it 'is valid with valid attributes' do
    expect(MfaEnrolmentForm.new({ code: 'abcdefg' })).to be_valid
  end

  it 'is not valid with no params' do
    expect(MfaEnrolmentForm.new({})).to_not be_valid
  end
end
