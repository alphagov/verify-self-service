require 'rails_helper'

RSpec.describe InviteUserForm, type: :model do

  it 'is valid with valid attributes' do
    expect(InviteUserForm.new({email: 'test@test.test', given_name: 'First Name', family_name: 'Surname', mfa: 'SOFTWARE_TOKEN_MFA', roles: [ROLE::CERTIFICATE_MANAGER] })).to be_valid
  end

  it 'is not valid with non-valid attributes' do
    expect(InviteUserForm.new({blah: 'blah'})).to_not be_valid
  end

  it 'is not valid with non-existent roles' do
    expect(InviteUserForm.new({email: 'test@test.test', given_name: 'First Name', family_name: 'Surname', mfa: 'SOFTWARE_TOKEN_MFA', roles: [ROLE::CERTIFICATE_MANAGER, 'blah'] })).to_not be_valid
  end

  it 'is not valid with a valid email' do
    expect(InviteUserForm.new({email: 'notanemailaddress', given_name: 'First Name', family_name: 'Surname', mfa: 'SOFTWARE_TOKEN_MFA' })).to_not be_valid
  end

  it 'is not valid without an MFA' do
    expect(InviteUserForm.new({email: 'test@test.test', given_name: 'First Name', family_name: 'Surname' })).to_not be_valid
  end

  it 'is not valid without a valid MFA' do
    expect(InviteUserForm.new({email: 'test@test.test', given_name: 'First Name', family_name: 'Surname', mfa: 'NON_EXISTENT_METHOD' })).to_not be_valid
  end

end
