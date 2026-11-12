# frozen_string_literal: true

require Rails.root.join("lib/dummy/signup_terms_stand_in")

Rails.application.config.to_prepare do
  next if defined?(RecordingStudioTermsAndConditions::ContinueNoticeHelper)

  RecordingStudioUser::ApplicationController.helper(Dummy::SignupTermsHelper)
end
