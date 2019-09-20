require 'rails_helper'

RSpec.describe SignInForm, type: :model do
  context 'sign in form' do
    it 'must have email' do
      form = SignInForm.new({email: nil, password: 'password1'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Email can\'t be blank')
    end

    it 'must be email formated' do
      form = SignInForm.new({email: 'testuser', password: 'password1'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Email is invalid')
    end

    it 'must have password' do
      form = SignInForm.new({email: 'test@test.com', password: nil})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Password can\'t be blank')
    end

    it 'password must be more than 8 characters long' do
      form = SignInForm.new({email: 'test@test.com', password: '1234567'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Password is too short (minimum is 8 characters)')
    end

    it 'form must pass validation' do
      form = SignInForm.new({email: 'test@test.com', password: 'password1'})
      expect(form.valid?).to eq(true)
    end
  end
end
