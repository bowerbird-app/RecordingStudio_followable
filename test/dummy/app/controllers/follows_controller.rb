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

  private

  def current_follow_root
    return unless respond_to?(:current_root_recording, true)

    send(:current_root_recording)
  end

  def can_view?(recording)
    RecordingStudioAccessible.authorized?(actor: current_user, recording: recording, role: :view)
  end
end
