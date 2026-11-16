class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def display_name
    email
  end

  # Users 0.31 refuses password sign-in until the account is confirmed.
  # Seeded and test password accounts are already real people. OTP sign-up
  # stays unconfirmed until the code step.
  def confirm_for_password_sign_in!
    return if confirmed?
    return if respond_to?(:registered_with_otp?) && registered_with_otp?

    update_column(:confirmed_at, Time.current)
  end
end
