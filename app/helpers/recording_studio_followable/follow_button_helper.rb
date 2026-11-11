# frozen_string_literal: true

module RecordingStudioFollowable
  module FollowButtonHelper
    include FollowButtonSignIn

    def follow_button(recording, root: nil, actor: nil)
      target = RecordingStudioFollowable::RecordingIdentity.recording_for(recording)
      follow_root = resolve_follow_button_root(root)
      follow_actor = resolve_follow_button_actor(actor)
      return unless show_follow_button?(follow_actor, follow_root, target)

      if follow_actor.blank?
        render_sign_in_follow_button(target)
      else
        render_follow_button(target, follow_root)
      end
    end

    def follow_target_url(recording)
      target = RecordingStudioFollowable::RecordingIdentity.recording_for(recording)
      custom = RecordingStudioFollowable.configuration.followed_url
      url = custom.call(target) if custom.respond_to?(:call)
      return url if url.present?

      default_followed_url(target)
    end

    def follow_target_title(follow_recording)
      target = follow_recording.recordable&.target_recording
      recordable = target&.recordable
      return "Unknown page" if recordable.blank?
      return recordable.title if recordable.respond_to?(:title)
      return recordable.name if recordable.respond_to?(:name)

      "Item"
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

    def render_sign_in_follow_button(target)
      embedded = follow_request_embedded?
      render FollowButtonComponent.new(
        target: target,
        root: nil,
        following: false,
        follow_url: nil,
        unfollow_url: nil,
        sign_in_url: follow_sign_in_url(target, embedded: embedded),
        embedded: embedded
      )
    end

    def show_follow_button?(actor, root, target)
      return false if target.blank?

      if actor.present?
        return false unless root.present? && Authorization.view?(actor: actor, recording: root)
        return true if following_target?(root, target)

        Visibility.see?(actor: actor, recording: target)
      else
        Visibility.see?(actor: nil, recording: target)
      end
    end

    def following_target?(root, target)
      RecordingStudioFollowable::FollowQuery.active_for(root: root, target: target).present?
    end

    def resolve_follow_button_root(root)
      return RecordingStudioFollowable::RecordingIdentity.follow_root_for(root) if root.present?

      RecordingStudioFollowable.configuration.resolve_current_root(self)
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
      return unless recordable

      if respond_to?(:main_app)
        main_app.polymorphic_path(recordable)
      else
        polymorphic_path(recordable)
      end
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
