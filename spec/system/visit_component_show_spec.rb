require 'rails_helper'

RSpec.describe 'New Component Page', type: :system do
  component_name = 'test component'
  component_params = {component_type: 'MSA', name: component_name}
  let(:component) { NewComponentEvent.create(component_params).component }

  it 'successfully creates a new component' do
    visit component_path(component.id)

    expect(page).to have_selector('h1', text: component_name)
    expect(page).to have_link 'Upload'
  end
end
