# frozen_string_literal: true

module RecordingStudioFollowable
  module Services
    class ListFollows
      def self.call(...)
        new(...).call
      end

      def initialize(root:, actor:)
        @root = RecordingIdentity.follow_root_for(root)
        @actor = actor
      end

      def call
        Authorization.assert_view!(actor: @actor, recording: @root)
        FollowQuery.for_root(@root)
      end
    end
  end
end
