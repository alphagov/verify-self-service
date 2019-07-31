require 'rails_helper'

RSpec.describe UserSignOutEvent, type: :model do
  let(:user_id) { SecureRandom.uuid }
  let(:event) { UserSignOutEvent.create(user_id: user_id) }
  let(:event_with_nil_user_id) {
    UserInfo.current_user = nil
    UserSignInEvent.create(user_id: nil)
  }

  context '#create' do
    it 'a valid event which contains a user id' do
      expect(event.user_id).to eq(user_id)
    end

    it 'a valid event with no user id' do
      expect(event_with_nil_user_id.user_id).to be_nil
    end
  end
end
