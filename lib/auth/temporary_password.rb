module TemporaryPassword
  MINIMUM_PASSWORD_LENGTH = 12
  def create_temporary_password
    temporary_password = ''
    until password_meets_criteria?(temporary_password) do
      temporary_password = generate_password
    end
    temporary_password
  end

  def generate_password
    SecureRandom.urlsafe_base64(12).insert(SecureRandom.random_number(11), SecureRandom.random_number(9).to_s)
  end

  def password_meets_criteria?(password)
    is_long_enough = password.length >= MINIMUM_PASSWORD_LENGTH
    has_uppercase = password =~ /[A-Z]/
    has_lowercase = password =~ /[a-z]/
    has_numbers = password =~ /[0-9]/

    is_long_enough && has_uppercase && has_lowercase && has_numbers
  end
end
