# frozen_string_literal: true

module RecordingStudioFollowable
  module Services
    class ListFollowers
      def self.call(...)
        new(...).call
      end

      def initialize(recording:, actor:)
        @recording = RecordingIdentity.recording_for(recording)
        @actor = actor
      end

      def call
        Authorization.assert_view!(actor: @actor, recording: @recording)
        FollowQuery.for_target(@recording)
      end
    end
  end
end
