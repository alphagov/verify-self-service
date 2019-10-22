RSpec.shared_examples "change component event" do |component_types|
  component_types.each do |component_type|
    context "#{component_type}" do
      it "is valid" do
        event = event(component_type)

        expect(event).to be_valid
        expect(event).to be_persisted
        expect(event.aggregate_type).to eq "#{component_type}_component".camelcase
      end

      it 'has changed attributes and record them in the data attribute' do
        setup(component_type)

        component = create(:sp_component)
        old_team_id = component.team_id
        new_team = create(:team)
        component.assign_attributes({team_id: new_team.id})
        event = ChangeComponentEvent.create(component: component)

        expect(new_team.id).not_to eq old_team_id
        expect(event.data).to eq({team_id: new_team.id}.stringify_keys)
        expect(event.component.team_id).to eq new_team.id
      end

      it 'errors when name is not present' do
        setup(component_type)

        @component.name = ""

        expect(@event).to_not be_valid
        expect(@event.errors[:name]).to eql [t('events.errors.missing_name')]
      end

      it 'errors when team is not present' do
        setup(component_type)

        @component.team_id = ""

        expect(@event).to_not be_valid
        expect(@event.errors[:team_id]).to eql [t('components.errors.invalid_team')]
      end

      it 'errors when environment is invalid' do
        setup(component_type)

        @component.environment = "fake-environment"

        expect(@event).to_not be_valid
        expect(@event.errors[:environment]).to eql [t('components.errors.invalid_environment')]
      end
    end
  end

  def setup(component_type)
    @event = event(component_type)
    @component = component(component_type)
  end

  def event(component_type)
    public_send("#{component_type}_change_event")
  end

  def component(component_type)
    public_send("#{component_type}_component")
  end
end
