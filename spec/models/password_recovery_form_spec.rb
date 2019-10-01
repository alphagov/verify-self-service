require 'rails_helper'

RSpec.describe PasswordRecoveryForm, type: :model do
  context 'forgotten passowrd form' do
    it 'e-mail cant be blank' do
      form = PasswordRecoveryForm.new({code: '000000', email: nil, password: 'password', password_confirmation: 'password'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Email can\'t be blank')
    end

    it 'email must be correctly uri formatted' do
      form = PasswordRecoveryForm.new({code: '000000', email: 'notanemail', password: 'password', password_confirmation: 'password'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Email is invalid')
    end

    it 'code cant be blank' do
      form = PasswordRecoveryForm.new({code: nil, email: 'test@test.com', password: 'password', password_confirmation: 'password'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Code can\'t be blank')
    end

    it 'password cant be blank' do
      form = PasswordRecoveryForm.new({code: '000000', email: 'test@test.com', password: nil, password_confirmation: 'password'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Password can\'t be blank')
    end

    it 'password confirmation cant be blank' do
      form = PasswordRecoveryForm.new({code: '000000', email: 'test@test.com', password: 'password', password_confirmation: nil})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Password confirmation can\'t be blank')
    end

    it 'password and password confirmation must match' do
      form = PasswordRecoveryForm.new({code: '000000', email: 'test@test.com', password: 'right123', password_confirmation: 'wrong123'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Password confirmation doesn\'t match Password')
    end

    it 'password must be more than 8 characters' do
      form = PasswordRecoveryForm.new({code: '000000', email: 'test@test.com', password: '1234567', password_confirmation: '1234567'})
      expect(form.valid?).to eq(false)
      expect(form.errors.full_messages[0]).to eq('Password is too short (minimum is 8 characters)')
    end

    it 'valids correctly' do
      form = PasswordRecoveryForm.new({code: '000000', email: 'test@test.com', password: 'password', password_confirmation: 'password'})
      expect(form.valid?).to eq(true)
    end
  end
end