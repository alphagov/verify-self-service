require 'rails_helper'

RSpec.describe UpdateUserEmailEvent, type: :model do
  let(:user_id) { SecureRandom.uuid }
  let(:email) { 'test@test.com' }
  let(:event) { UpdateUserEmailEvent.create(user_id: user_id, data: { user_id: '0', email: email }) }

  context '#create' do
    it 'a valid event which contains a user id and email' do
      expect(event.data["user_id"]).to eq('0')
      expect(event.data["email"]).to eq(email)
    end
  end
end
