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

  it 'is not valid with a valid email' do
    expect(InviteUserForm.new({email: 'notanemailaddress', given_name: 'First Name', family_name: 'Surname' })).to_not be_valid
  end
end
