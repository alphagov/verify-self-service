require 'rails_helper'

RSpec.describe Service, type: :model do
  context 'adding components to a service' do
    let(:sp_component) { create(:sp_component) }
    let(:msa_component) { create(:msa_component) }
    let(:service) { create(:service, sp_component: sp_component) }

    it 'should create a new service correctly' do
      expect(service).to be_valid
      expect(service).to be_persisted
    end

    it 'should be able to have an sp and msa component' do
      service.msa_component = msa_component
      expect(service).to be_valid
      expect(service).to be_persisted
    end
  end

  context 'creating a spec without an initial component' do
    let(:service) { create(:service) }

    it 'should create a new service correctly' do
      expect(service).to be_valid
      expect(service).to be_persisted
    end
  end
end
