require 'rails_helper'

RSpec.describe UpdateUserRolesForm, type: :model do

  it 'is valid with valid roles' do
    expect(UpdateUserRolesForm.new(roles: [ROLE::CERTIFICATE_MANAGER] )).to be_valid
  end

  it 'is not valid with no valid roles' do
    expect(UpdateUserRolesForm.new(roles: ['blah'])).to_not be_valid
  end

  it 'is not valid with any non-valid roles' do
    expect(UpdateUserRolesForm.new(roles: [ROLE::CERTIFICATE_MANAGER, 'blah'])).to_not be_valid
  end

end
