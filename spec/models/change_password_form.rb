require 'rails_helper'

RSpec.describe ChangePasswordForm, type: :model do
  context 'passowrd form' do
    it 'must have old_password' do
      form = ChangePasswordForm.new({old_password: nil, password: 'password1', password_confirmation: 'password1'})
      form.valid?
      expect(form.errors.full_messages[0]).to eq('Old password can\'t be blank')
    end

    it 'must have password' do
      form = ChangePasswordForm.new({old_password: 'password', password: nil, password_confirmation: 'password1'})
      form.valid?
      expect(form.errors.full_messages[0]).to eq('Password can\'t be blank')
    end

    it 'must have password confirmation' do
      form = ChangePasswordForm.new({old_password: 'password', password: 'password1', password_confirmation: nil})
      form.valid?
      expect(form.errors.full_messages[0]).to eq('Password confirmation can\'t be blank')
    end

    it 'password and password confirmation must match' do
      form = ChangePasswordForm.new({old_password: 'password', password: 'password1', password_confirmation: 'password2'})
      form.valid?
      expect(form.errors.full_messages[0]).to eq('Password confirmation doesn\'t match Password')
    end

    it 'password must have at least 8 characters' do
      form = ChangePasswordForm.new({old_password: 'password', password: '1234567', password_confirmation: '1234567'})
      form.valid?
      expect(form.errors.full_messages[0]).to eq('Password is too short (minimum is 8 characters)')
    end

    it 'is valid when everything is supplied' do
      form = ChangePasswordForm.new({old_password: 'password', password: 'password1', password_confirmation: 'password1'})
      expect(form.valid?).to eq(true)
    end
  end
end