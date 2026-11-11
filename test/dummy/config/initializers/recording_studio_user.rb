# frozen_string_literal: true

RecordingStudioUser.configure do |config|
  config.otp_enabled = true
  config.otp_registration_channels = %i[email]
  config.otp_login_channels = %i[email]
end

Rails.application.config.to_prepare do
  RecordingStudioUser::Engine.apply_otp_setup!(User)
end
