class AggregatedEvent < Event
  self.abstract_class = true
  before_validation :preset_aggregate
  before_create :apply_and_persist_changes_to_aggregate

  def preset_aggregate
    self.aggregate ||= build_aggregate
  end

  def build_aggregate
    public_send "build_#{aggregate_name}"
  end

  def self.belongs_to_aggregate(aggregate_name)
    @aggregate_name = aggregate_name
    belongs_to :aggregate, polymorphic: true, autosave: false
    define_method :aggregate_name do
      aggregate_name
    end
    alias_attribute aggregate_name, :aggregate
  end

  def apply_and_persist_changes_to_aggregate
    self.aggregate.lock! if aggregate_exists_and_unchanged?

    self.aggregate.assign_attributes(attributes_to_apply)

    self.aggregate.save!
    self.aggregate_id = aggregate.id if aggregate_id.nil?
  end

  def attributes_to_apply
    raise NotImplementedError
  end

  def name_is_present
    errors.add(:name, I18n.t('events.errors.missing_name')) unless name.present?
  end

  def strip_entity_id
    self.entity_id = entity_id.strip unless entity_id.nil?
  end

private

  def aggregate_exists_and_unchanged?
    self.aggregate.persisted? && !self.aggregate.changed?
  end
end
