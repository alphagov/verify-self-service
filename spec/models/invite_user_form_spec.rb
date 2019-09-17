require 'rails_helper'

RSpec.describe InviteUserForm, type: :model do

  it 'is valid with valid attributes' do
    expect(InviteUserForm.new({email: 'test@test.test', given_name: 'First Name', family_name: 'Surname', roles: [ROLE::CERTIFICATE_MANAGER] })).to be_valid
  end

  it 'is not valid with non-valid attributes' do
    expect(InviteUserForm.new({blah: 'blah'})).to_not be_valid
  end

  it 'is not valid with non-existent roles' do
    expect(InviteUserForm.new({email: 'test@test.test', given_name: 'First Name', family_name: 'Surname', roles: [ROLE::CERTIFICATE_MANAGER, 'blah'] })).to_not be_valid
  end

  it 'is not valid with an invalid email' do
    expect(InviteUserForm.new({email: 'notanemailaddress', given_name: 'First Name', family_name: 'Surname' })).to_not be_valid
  end

  it 'is not valid when GDS role is being assigned to a non-GDS email' do
    expect(InviteUserForm.new({email: 'test@test.test', given_name: 'First Name', family_name: 'Surname', roles: [ROLE::GDS] })).to_not be_valid
  end

  it 'is valid when GDS role is being assigned to a GDS email' do
    expect(InviteUserForm.new({email: 'test@digital.cabinet-office.gov.uk', given_name: 'First Name', family_name: 'Surname', roles: [ROLE::GDS] })).to be_valid
  end
end
