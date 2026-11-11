# frozen_string_literal: true

module RecordingStudioFollowable
  module FollowButtonHelper
    def follow_button(recording, root: nil, actor: nil)
      target = RecordingStudioFollowable::RecordingIdentity.recording_for(recording)
      follow_root = resolve_follow_button_root(root)
      follow_actor = resolve_follow_button_actor(actor)
      return unless can_render_follow_button?(follow_actor, follow_root)

      render_follow_button(target, follow_root)
    end

    def follow_target_url(recording)
      target = RecordingStudioFollowable::RecordingIdentity.recording_for(recording)
      custom = RecordingStudioFollowable.configuration.followed_url
      url = custom.call(target) if custom.respond_to?(:call)
      return url if url.present?

      default_followed_url(target)
    end

    private

    def render_follow_button(target, follow_root)
      follows_url = follow_button_follows_path
      render FollowButtonComponent.new(
        target: target,
        root: follow_root,
        following: following_target?(follow_root, target),
        follow_url: follows_url,
        unfollow_url: follows_url
      )
    end

    def can_render_follow_button?(actor, root)
      actor.present? && root.present? &&
        RecordingStudioAccessible.authorized?(actor: actor, recording: root, role: :view)
    end

    def following_target?(root, target)
      RecordingStudioFollowable::FollowQuery.active_for(root: root, target: target).present?
    end

    def resolve_follow_button_root(root)
      return RecordingStudioFollowable::RecordingIdentity.follow_root_for(root) if root.present?
      return unless respond_to?(:current_root_recording, true)

      current_root_recording
    end

    def follow_button_follows_path
      if respond_to?(:recording_studio_followable)
        recording_studio_followable.follows_path
      else
        follows_path
      end
    end

    def default_followed_url(target)
      recordable = target&.recordable
      return unless recordable && respond_to?(:polymorphic_path)

      polymorphic_path(recordable)
    rescue ArgumentError, NoMethodError, ActionController::UrlGenerationError
      nil
    end

    def resolve_follow_button_actor(actor)
      return actor if actor.present?
      return current_user if respond_to?(:current_user, true) && current_user.present?
      return unless RecordingStudio.configuration.respond_to?(:actor)

      RecordingStudio.configuration.actor&.call
    end
  end
end
