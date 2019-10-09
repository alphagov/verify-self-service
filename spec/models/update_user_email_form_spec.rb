require 'rails_helper'

RSpec.describe UpdateUserEmailForm, type: :model do
  context 'model' do
    it 'must have email' do
      form = UpdateUserEmailForm.new({email: nil})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Email can\'t be blank')
    end

    it 'must be a valid email' do
      form = UpdateUserEmailForm.new({email: 'not a valid e-mail'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Email is invalid')
    end

    it 'must validate' do
      form = UpdateUserEmailForm.new({email: 'test@test.com'})
      expect(form.valid?).to eq(true)
    end
  end
end