class Event < ApplicationRecord
  include UserInfo
  after_initialize :default_values
  scope :newest_first, -> { order('created_at DESC') }

private

  def default_values
    self.data ||= {}
    self.user_id ||= current_user&.user_id
  end

  def self.data_attributes(*names) # rubocop:disable  IneffectiveAccessModifier
    names.each do |name|
      define_method name do
        self.data ||= {}
        self.data[name.to_s]
      end
      define_method "#{name}=" do |value|
        self.data ||= {}
        self.data[name.to_s] = value
      end
    end
  end
end
