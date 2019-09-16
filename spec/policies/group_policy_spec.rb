require 'rails_helper'

describe GroupPolicy do
  subject { GroupPolicy }

  permissions :new?, :create?, :invite? do
    it "denies when the user's team differs from the object's one" do
      expect(subject).not_to permit(FactoryBot.create(:user_manager_user), FactoryBot.create(:team, id: SecureRandom.uuid))
    end

    it "grants access when the user's team matches the object's one" do
      user_manager_user = FactoryBot.create(:user_manager_user)
      expect(subject).to permit(user_manager_user, Team.find_by_id(user_manager_user.team))
    end

    it 'grants access when the GDS user' do
      expect(subject).to permit(FactoryBot.create(:gds_user), FactoryBot.create(:team, id: SecureRandom.uuid))
    end
  end
end
