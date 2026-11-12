# frozen_string_literal: true

module RecordingStudioFollowable
  module Visibility
    module_function

    def see?(actor:, recording:)
      return false if recording.blank?
      return true if Authorization.view?(actor: actor, recording: recording)

      public_audience?(actor, recording)
    end

    def public_audience?(actor, recording)
      return false unless defined?(RecordingStudioAccessible::AudienceAuthorization)

      action = RecordingStudioFollowable.configuration.visibility_action
      return false if action.blank?

      RecordingStudioAccessible::AudienceAuthorization.authorized?(
        actor: actor,
        action: action.to_sym,
        recording: recording
      )
    end
  end
end
