require 'rails_helper'

describe GroupPolicy do
  subject { GroupPolicy }

  permissions :new?, :create?, :invite? do
    it "denies when the user's team differs from the object's one" do
      expect(subject).not_to permit(FactoryBot.create(:user_manager_user), FactoryBot.create(:team, id: 99))
    end

    it "grants access when the user's team matches the object's one" do
      expect(subject).to permit(FactoryBot.create(:user_manager_user),  FactoryBot.create(:team))
    end

    it "grants access when the GDS user" do
      expect(subject).to permit(FactoryBot.create(:gds_user), FactoryBot.create(:team, id: 99))
    end
  end
end