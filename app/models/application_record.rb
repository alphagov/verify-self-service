class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def errors?
    errors.any?
  end
end
