# frozen_string_literal: true

module RecordingStudioFollowable
  module Services
    class Follow
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
        raise NotAuthorized, "not authorized" unless Visibility.see?(actor: @actor, recording: @target)
        raise InvalidFollow, "cannot follow a follow" if follow_target?

        @root.with_lock do
          existing = FollowQuery.active_for(root: @root, target: @target)
          return existing if existing

          create_follow!
        end
      end

      private

      def create_follow!
        follow = RecordingStudioFollowable::Follow.new(target_recording_id: @target.id)
        RecordingStudio.record!(
          action: "created",
          recordable: follow,
          root_recording: @root,
          parent_recording: @root,
          actor: @actor,
          idempotency_key: idempotency_key
        ).recording
      end

      def follow_target?
        @target.recordable_type == "RecordingStudioFollowable::Follow"
      end

      def idempotency_key
        "followable/follow/#{@root.id}/#{@target.id}"
      end
    end
  end
end
