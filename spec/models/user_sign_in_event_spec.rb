require 'rails_helper'

RSpec.describe UserSignInEvent, type: :model do

  user_id = SecureRandom.uuid
  let(:user_id) { SecureRandom.uuid }
  let(:event) { UserSignInEvent.create(user_id: user_id) }

  context '#create' do
    it 'creates a valid sign in event with user id' do
      expect(event.data).to include(
        'user_id'
      )
      expect(event.data['user_id']).to eq(user_id)
    end
  end
end
