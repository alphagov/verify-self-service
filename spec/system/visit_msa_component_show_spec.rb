require 'rails_helper'

RSpec.describe 'New MSA Component Page', type: :system do
  include_examples 'show component page', CONSTANTS::MSA
end
