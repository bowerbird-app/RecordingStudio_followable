# frozen_string_literal: true

module RecordingStudioFollowable
  module Api
    module Actions
      FOLLOW_SERIALIZER = lambda do |recording, **|
        follow = recording.recordable
        {
          id: recording.id,
          type: recording.recordable_type,
          root_id: recording.root_recording_id,
          parent_id: recording.parent_recording_id,
          target_id: follow.target_recording_id
        }
      end

      module Follow
        def self.call(context)
          root = RecordingStudio::Recording.find(root_id_from(context))
          recording = RecordingStudioFollowable.follow(
            target: context.recording,
            root: root,
            actor: context.actor
          )
          Actions::FOLLOW_SERIALIZER.call(recording)
        rescue RecordingStudioFollowable::NotAuthorized
          deny_follow!
        end

        def self.deny_follow!
          if defined?(RecordingStudioApi::AuthorizationError)
            raise RecordingStudioApi::AuthorizationError, "not authorized"
          end

          raise RecordingStudioFollowable::NotAuthorized, "not authorized"
        end

        def self.root_id_from(context)
          params = context.params || {}
          params[:root_id].presence || params["root_id"]
        end
      end

      module Unfollow
        def self.call(context)
          root = RecordingStudio::Recording.find(Follow.root_id_from(context))
          recording = RecordingStudioFollowable.unfollow(
            target: context.recording,
            root: root,
            actor: context.actor
          )
          recording ? Actions::FOLLOW_SERIALIZER.call(recording) : { unfollowed: true }
        rescue RecordingStudioFollowable::NotAuthorized
          Follow.deny_follow!
        end
      end

      module Followers
        def self.call(context)
          context.access_grant.authorize!(recording: context.recording, role: :view)
          RecordingStudioFollowable.followers(recording: context.recording, actor: context.actor).map do |recording|
            Actions::FOLLOW_SERIALIZER.call(recording)
          end
        end
      end

      module Follows
        def self.call(context)
          context.access_grant.authorize!(recording: context.recording, role: :view)
          RecordingStudioFollowable.follows(root: context.recording, actor: context.actor).map do |recording|
            Actions::FOLLOW_SERIALIZER.call(recording)
          end
        end
      end
    end
  end
end
