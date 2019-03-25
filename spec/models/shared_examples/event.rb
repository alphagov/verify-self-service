RSpec.shared_examples "has data attributes" do |klass, attribute_names|
  let(:value) { double(:value) }
  attribute_names.each do |name|
    it "#{name} can be added at initialize time" do
      event = klass.new(name => value)
      expect(event.public_send(name)).to eql value
      expect(event.data[name.to_s]).to eql value
    end

    it "#{name} is stored in the data column" do
      event = klass.new
      event.public_send("#{name}=", value)
      expect(event.public_send(name)).to eql value
      expect(event.data[name.to_s]).to eql value
    end
  end
end

RSpec.shared_examples "is aggregated" do |klass, parameters|
  it "has an aggregate" do
    event = klass.create!(parameters)
    expect(event.aggregate).to_not be_nil
    expect(event.aggregate_id).to eq(event.aggregate.id)
    expect(event.aggregate).to be_persisted
    expect(event.public_send(event.aggregate_name)).to eq(event.aggregate)
  end

  it "updates an attribute" do
    event = klass.new(parameters)
    aggregate = event.build_aggregate
    attributes = aggregate.attributes
    event.save!
    expect(event.aggregate.attributes).to_not eql attributes
  end
end

RSpec.shared_examples "is a creation event" do |klass, parameters|
  include_examples "is aggregated", klass, parameters
  it "that also creates an aggregate" do
    event = klass.new(parameters)
    expect(event.aggregate).to be_nil
    event.save!
    expect(event).to be_valid
    expect(event).to be_persisted
    event.reload
    expect(event.aggregate).to_not be_nil
    expect(event.aggregate).to be_persisted
    expect(event.public_send(event.aggregate_name)).to eql event.aggregate
    expect(event.created_at).to eql event.aggregate.created_at
  end

  it "cannot be attached to an aggregate that already exists" do

    first_event = klass.create(parameters)
    expect(first_event).to be_persisted
    aggregate = first_event.aggregate
    expect(aggregate).to be_persisted
    
    second_event = klass.create(parameters.merge(aggregate: aggregate))
    expect(second_event).to_not be_valid
    expect(second_event).to_not be_persisted
    expect(second_event.errors[second_event.aggregate_name]).to eql ["already exists"]
  end
end
