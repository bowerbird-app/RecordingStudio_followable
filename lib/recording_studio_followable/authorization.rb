# frozen_string_literal: true

module RecordingStudioFollowable
  module Authorization
    module_function

    def assert_view!(actor:, recording:)
      return if view?(actor: actor, recording: recording)

      raise NotAuthorized, "not authorized"
    end

    def view?(actor:, recording:)
      return false if actor.blank? || recording.blank?
      return false unless defined?(RecordingStudioAccessible)

      RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)
    end
  end
end
