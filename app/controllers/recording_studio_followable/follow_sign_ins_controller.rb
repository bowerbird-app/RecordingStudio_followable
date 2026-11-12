# frozen_string_literal: true

module RecordingStudioFollowable
  class FollowSignInsController < ApplicationController
    skip_before_action :authenticate_user!, only: :new, raise: false

    def new
      intent = FollowIntent.read(params[:intent])
      return redirect_missing if intent.blank?

      @return_to = follow_sign_in_path(intent: params[:intent])
    end

    def create
      intent = FollowIntent.read(params[:intent])
      target = recording_for(intent)
      return redirect_missing if target.blank?

      root = usable_root
      return redirect_setup if root.blank?

      RecordingStudioFollowable.follow(target: target, root: root, actor: follow_actor)
      render_followed(intent, target, root)
    rescue NotAuthorized
      redirect_to destination(intent, target), alert: I18n.t("recording_studio_followable.follows.unauthorized")
    end

    def setup; end

    private

    def render_followed(intent, target, root)
      @target_recording = target
      @follow_root = root
      @button_overrides = button_overrides(intent)
      @button_frame_id = FollowButtonComponent.frame_id(target: target, root: nil)
      respond_to do |format|
        format.turbo_stream { render template: "recording_studio_followable/follows/button" }
        format.html { redirect_to destination(intent, target) }
      end
    end

    def recording_for(intent)
      return if intent.blank?

      RecordingStudio::Recording.find_by(id: intent.target_id)
    end

    def usable_root
      root = RecordingStudioFollowable.configuration.resolve_current_root(self)
      return if root.blank?
      return unless Authorization.view?(actor: follow_actor, recording: root)

      root
    end

    def redirect_setup
      url = setup_url
      if url.present?
        redirect_to url
      else
        redirect_to follow_sign_in_setup_path
      end
    end

    def setup_url
      configured = RecordingStudioFollowable.configuration.account_setup_url
      return if configured.blank?

      configured.respond_to?(:call) ? configured.call(self) : configured.to_s
    end

    def redirect_missing
      redirect_to main_app.root_path, alert: I18n.t("recording_studio_followable.sign_in.missing_page")
    end

    def destination(intent, target)
      ReturnTo.preferred(
        parent_url: intent&.parent_url,
        return_to: intent&.page,
        canonical: helpers.follow_target_url(target).presence || main_app.root_path,
        host: request.host,
        allowed_origins: RecordingStudioFollowable.configuration.allowed_return_origins
      )
    end

    def button_overrides(intent)
      ButtonAppearance.parse(intent.button)
    rescue ArgumentError
      {}
    end

    def follow_actor
      user = current_user if respond_to?(:current_user, true)
      user.presence || (defined?(Current) ? Current.actor : nil)
    end
  end
end
