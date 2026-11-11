# frozen_string_literal: true

class FollowsController < ApplicationController
  def index
    @follow_root = current_follow_root
    unless @follow_root && can_view?(@follow_root)
      redirect_to root_path, alert: "Pick a workspace first."
      return
    end

    @follows = RecordingStudioFollowable.follows(root: @follow_root, actor: current_user)
  end

  def create
    RecordingStudioFollowable.follow(
      target: target_recording,
      root: follow_root_from_params,
      actor: current_user
    )
    redirect_back fallback_location: follows_path, notice: "You’re following it."
  rescue RecordingStudioFollowable::NotAuthorized, ActiveRecord::RecordNotFound
    redirect_back fallback_location: root_path, alert: "You can’t follow that."
  end

  def destroy
    RecordingStudioFollowable.unfollow(
      target: target_recording,
      root: follow_root_from_params,
      actor: current_user
    )
    redirect_back fallback_location: follows_path, notice: "You’re not following it any more."
  rescue RecordingStudioFollowable::NotAuthorized, ActiveRecord::RecordNotFound
    redirect_back fallback_location: root_path, alert: "You can’t change that follow."
  end

  private

  def current_follow_root
    return unless respond_to?(:current_root_recording, true)

    send(:current_root_recording)
  end

  def follow_root_from_params
    RecordingStudio::Recording.find(params.require(:root_id))
  end

  def target_recording
    RecordingStudio::Recording.find(params.require(:target_id))
  end

  def can_view?(recording)
    RecordingStudioAccessible.authorized?(actor: current_user, recording: recording, role: :view)
  end
end
