class DeleteComponentEvent < AggregatedEvent
  belongs_to_aggregate :component
  after_save :destroy

  def attributes_to_apply
    {}
  end

private

  def destroy
    component.destroy!
  end
end
