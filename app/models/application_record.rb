class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def errors?
    self.errors.any?
  end
end
