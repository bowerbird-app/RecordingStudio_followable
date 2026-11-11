# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @follow_root = current_follow_root
    @page = Page.find_by(title: "Getting Started")
    @page_recording = page_recording_for(@page)
    @following = following_demo_page?
    @follows = follows_for_current_root
  end

  private

  def current_follow_root
    return unless respond_to?(:current_root_recording, true)

    send(:current_root_recording)
  end

  def page_recording_for(page)
    return if page.blank?

    RecordingStudio::Recording.where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
                              .find_by(recordable: page)
  end

  def following_demo_page?
    return false if @follow_root.blank? || @page_recording.blank?
    return false unless can_view?(@follow_root) && can_view?(@page_recording)

    RecordingStudioFollowable::FollowQuery.active_for(root: @follow_root, target: @page_recording).present?
  end

  def follows_for_current_root
    return RecordingStudio::Recording.none if @follow_root.blank?
    return RecordingStudio::Recording.none unless can_view?(@follow_root)

    RecordingStudioFollowable.follows(root: @follow_root, actor: current_user)
  end

  def can_view?(recording)
    RecordingStudioAccessible.authorized?(actor: current_user, recording: recording, role: :view)
  end
end
