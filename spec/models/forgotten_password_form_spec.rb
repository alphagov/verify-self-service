require 'rails_helper'

RSpec.describe ForgottenPasswordForm, type: :model do
  context 'forgotten passowrd form' do
    it 'e-mail cant be blank' do
      form = ForgottenPasswordForm.new({email: nil})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Email can\'t be blank')
    end

    it 'e-mail must be correctly uri formatted' do
      form = ForgottenPasswordForm.new({email: 'notanemail'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Email is invalid')
    end

    it 'valids correctly' do
      form = ForgottenPasswordForm.new({email: 'test@test.com'})
      expect(form.valid?).to eq(true)
    end
  end
end