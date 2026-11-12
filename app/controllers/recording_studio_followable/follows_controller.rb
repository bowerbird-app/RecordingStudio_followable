# frozen_string_literal: true

module RecordingStudioFollowable
  class FollowsController < ApplicationController
    def index
      @follow_root = configured_root
      raise RecordingStudioFollowable::NotAuthorized if @follow_root.blank? || !view_on_root?(@follow_root)

      assign_follows_page
      render_xhr_rows if request.xhr?
    rescue RecordingStudioFollowable::NotAuthorized, ActiveRecord::RecordNotFound
      respond_unauthorized
    end

    def create
      mutate_follow(:follow)
    end

    def destroy
      mutate_follow(:unfollow)
    end

    private

    def render_xhr_rows
      render partial: "rows", locals: { follows: @follows, next_cursor: @next_cursor }, layout: false
    end

    def assign_follows_page
      page = RecordingStudioFollowable.follows(
        root: @follow_root,
        actor: follow_actor,
        limit: RecordingStudioFollowable.configuration.page_size,
        cursor: params[:cursor]
      )
      @follows = page.records
      @next_cursor = page.next_cursor
    end

    def mutate_follow(action)
      @button_overrides = button_overrides
      RecordingStudioFollowable.public_send(
        action,
        target: target_recording,
        root: follow_root,
        actor: follow_actor
      )
      respond_after_change
    rescue RecordingStudioFollowable::NotAuthorized, ActiveRecord::RecordNotFound
      respond_unauthorized
    end

    def respond_after_change
      respond_to do |format|
        format.turbo_stream { render :button }
        format.html { redirect_back_or_to after_change_fallback }
      end
    end

    def respond_unauthorized
      respond_to do |format|
        format.turbo_stream { head :forbidden }
        format.html do
          redirect_back_or_to after_change_fallback, alert: I18n.t("recording_studio_followable.follows.unauthorized")
        end
      end
    end

    def target_recording
      @target_recording ||= RecordingStudio::Recording.find(params.require(:target_id))
    end

    def follow_root
      @follow_root ||= resolve_follow_root
      raise ActiveRecord::RecordNotFound, "a follow root is required" if @follow_root.blank?

      @follow_root
    end

    def resolve_follow_root
      root_id = params.permit(:root_id).fetch(:root_id, nil)
      if root_id.present?
        RecordingStudio::Recording.find(root_id)
      else
        configured_root
      end
    end

    def configured_root
      RecordingStudioFollowable.configuration.resolve_current_root(self)
    end

    def view_on_root?(root)
      RecordingStudioAccessible.authorized?(actor: follow_actor, recording: root, role: :view)
    end

    def follow_actor
      actor = current_user if respond_to?(:current_user, true)
      actor ||= RecordingStudio.configuration.actor&.call
      raise RecordingStudioFollowable::NotAuthorized, "an actor is required" if actor.blank?

      actor
    end

    def after_change_fallback
      main_app.respond_to?(:root_path) ? main_app.root_path : "/"
    end

    def button_overrides
      permitted = params.permit(ButtonAppearance::PARAM_KEY => ButtonAppearance.permit_shape)
      ButtonAppearance.parse(permitted.to_h[ButtonAppearance::PARAM_KEY.to_s])
    end
  end
end
