require 'yaml'
require 'rails_helper'

RSpec.describe UserSignInEvent, type: :model do
  let(:user_id) { SecureRandom.uuid }
  let(:event) { UserSignInEvent.create(user_id: user_id) }

  context '#create' do
    it 'a valid event which contains the user id' do

      expect(event.user_id).to eq(user_id)
    end
  end
end
