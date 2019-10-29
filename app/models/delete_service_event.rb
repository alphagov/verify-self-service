class DeleteServiceEvent < AggregatedEvent
  belongs_to_aggregate :service
  after_save :destroy

  def attributes_to_apply
    {}
  end

private

  def destroy
    service.destroy!
  end
end
