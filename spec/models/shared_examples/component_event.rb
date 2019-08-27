RSpec.shared_examples "components have data attributes" do |type, attributes|
  attributes.each do |k, v|
    it "#{k} can be added at initialize time" do
      event = build(type, k => v)
      expect(event.public_send(k)).to eql v
      expect(event.data[k.to_s]).to eql v
    end

    it "#{k} is stored in the data column" do
      event = create(type, attributes)
      event.public_send("#{k}=", v)
      expect(event.public_send(k)).to eql v
      expect(event.data[k.to_s]).to eql v
    end
  end
end

RSpec.shared_examples "components are aggregated" do |type, attributes = {}|
  it "has an aggregate" do
    event = create(type, attributes)
    expect(event.aggregate).to_not be_nil
    expect(event.aggregate_id).to eq(event.aggregate.id)
    expect(event.aggregate).to be_persisted
    expect(event.public_send(event.aggregate_name)).to eq(event.aggregate)
  end

  it "updates an attribute" do
    event = create(type, attributes)
    aggregate = event.build_aggregate
    event.save!
    expect(event.aggregate.attributes).to_not eql aggregate.attributes
  end
end

RSpec.shared_examples "component creation event" do |type, attributes = {}|
  include_examples "components are aggregated", type
  it "that also creates an aggregate" do
    event = create(type, attributes)
    expect(event).to be_valid
    expect(event).to be_persisted
    event.reload
    expect(event.aggregate).to_not be_nil
    expect(event.aggregate).to be_persisted
    expect(event.public_send(event.aggregate_name)).to eql event.aggregate
    expect(event.created_at).to eql event.aggregate.created_at
  end

  it "cannot be attached to an aggregate that already exists" do
    first_event = create(type, attributes)
    expect(first_event).to be_persisted
    aggregate = first_event.aggregate
    expect(aggregate).to be_persisted

    expect {
      create(type, attributes.merge(aggregate: aggregate))
    }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
