require 'rails_helper'

RSpec.describe 'New SP Component Page', type: :system do
  include_examples 'show component page', CONSTANTS::SP
end
