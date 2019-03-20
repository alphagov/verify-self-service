require 'rails_helper'

RSpec.describe NewComponentEvent, type: :model do

  include_examples 'has data attributes', NewComponentEvent, [:name, :component_type]
  include_examples 'is aggregated', NewComponentEvent, {name: 'New component', component_type: 'MSA' }
  include_examples 'is a creation event', NewComponentEvent, {name: 'New component', component_type: 'MSA'}

end
