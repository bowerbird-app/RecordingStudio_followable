# frozen_string_literal: true

module RecordingStudioFollowable
  module FollowSignInFinish
    private

    def finish_follow
      state = sign_in_state
      session.delete(self.class::SESSION_KEY)
      target = RecordingStudio::Recording.find_by(id: state["target_id"])
      return redirect_to(safe_destination(state, nil), alert: missing_page_message) if target.blank?
      return render_setup unless usable_follow_root?

      follow_and_return(state, target)
    rescue NotAuthorized
      redirect_to safe_destination(state, target), alert: I18n.t("recording_studio_followable.follows.unauthorized")
    end

    def usable_follow_root?
      root = RecordingStudioFollowable.configuration.resolve_current_root(self)
      root.present? && Authorization.view?(actor: signed_in_actor, recording: root)
    end

    def render_setup
      return redirect_to(setup_url) if setup_url.present?

      render :setup
    end

    def follow_and_return(state, target)
      root = RecordingStudioFollowable.configuration.resolve_current_root(self)
      RecordingStudioFollowable.follow(target: target, root: root, actor: signed_in_actor)
      redirect_to safe_destination(state, target)
    end

    def setup_url
      configured = RecordingStudioFollowable.configuration.account_setup_url
      return if configured.blank?

      configured.respond_to?(:call) ? configured.call(self) : configured.to_s
    end

    def safe_destination(state, target)
      ReturnTo.preferred(
        parent_url: state["parent_url"],
        return_to: state["return_to"],
        canonical: canonical_url(target),
        host: request.host,
        allowed_origins: RecordingStudioFollowable.configuration.allowed_return_origins
      )
    end

    def canonical_url(target)
      return main_app.root_path if target.blank?

      helpers.follow_target_url(target).presence || main_app.root_path
    end

    def missing_page_message
      I18n.t("recording_studio_followable.sign_in.missing_page")
    end
  end
end
