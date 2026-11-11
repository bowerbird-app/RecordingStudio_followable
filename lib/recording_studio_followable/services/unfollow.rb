# frozen_string_literal: true

module RecordingStudioFollowable
  module Services
    class Unfollow
      def self.call(...)
        new(...).call
      end

      def initialize(target:, root:, actor:)
        @target = RecordingIdentity.recording_for(target)
        @root = RecordingIdentity.follow_root_for(root)
        @actor = actor
      end

      def call
        Authorization.assert_view!(actor: @actor, recording: @root)

        @root.with_lock do
          follow_recording = FollowQuery.active_for(root: @root, target: @target)
          return nil unless follow_recording

          follow_recording.recording_studio_trashable_trash!(actor: @actor)
          follow_recording
        end
      end
    end
  end
end
