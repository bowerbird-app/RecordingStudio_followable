# frozen_string_literal: true

module RecordingStudioFollowable
  class FollowSignInsController < ApplicationController
    include FollowSignInFinish

    SESSION_KEY = :recording_studio_followable_sign_in

    skip_before_action :authenticate_user!, raise: false

    def new
      remember_target!
      return finish_follow if signed_in_actor.present?

      render :new
    end

    def create
      remember_target!
      EmailCode.request!(email: submitted_email, request: request, session: session)
      redirect_to follow_sign_in_verify_path
    rescue EmailCode::Failed => e
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    end

    def verify
      render :verify
    end

    def submit
      user = EmailCode.verify!(code: params[:code], session: session)
      sign_in_actor(user)
      finish_follow
    rescue EmailCode::Failed => e
      flash.now[:alert] = e.message
      render :verify, status: :unprocessable_entity
    end

    private

    def remember_target!
      session[SESSION_KEY] = sign_in_state.merge(incoming_sign_in_state)
    end

    def incoming_sign_in_state
      state = {}
      state["target_id"] = params[:target_id] if params[:target_id].present?
      state["email"] = submitted_email if params[:email].present?
      state.merge(return_state)
    end

    def return_state
      state = {}
      state["return_to"] = params[:return_to] if params.key?(:return_to)
      state["parent_url"] = params[:parent_url] if params.key?(:parent_url)
      state
    end

    def submitted_email
      params[:email].presence || sign_in_state["email"]
    end

    def sign_in_state
      raw = session[SESSION_KEY]
      raw.respond_to?(:to_h) ? raw.to_h.stringify_keys : {}
    end

    def signed_in_actor
      actor = current_user if respond_to?(:current_user, true)
      actor.presence || (defined?(Current) ? Current.actor : nil)
    end

    def sign_in_actor(user)
      if respond_to?(:sign_in, true) && defined?(Devise::Mapping)
        sign_in(Devise::Mapping.find_scope!(user), user)
      elsif (warden = request.env["warden"])
        warden.set_user(user, scope: :user)
      end
      Current.actor = user if defined?(Current)
    end
  end
end
