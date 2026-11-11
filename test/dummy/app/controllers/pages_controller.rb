# frozen_string_literal: true

class PagesController < ApplicationController
  def index
    @pages = pages_in_current_root
  end

  def show
    @page = Page.find(params[:id])
    @page_recording = page_recording_for(@page)
    raise ActiveRecord::RecordNotFound unless @page_recording
    raise RecordingStudioFollowable::NotAuthorized unless can_view?(@page_recording)

    @follow_root = current_follow_root
    @following = following_page?
  rescue RecordingStudioFollowable::NotAuthorized
    redirect_to pages_path, alert: "You don’t have access to that page."
  end

  def notify_followers
    @page = Page.find(params[:id])
    @page_recording = page_recording_for(@page)
    raise ActiveRecord::RecordNotFound unless @page_recording
    raise RecordingStudioFollowable::NotAuthorized unless can_view?(@page_recording)

    RecordingStudioFollowable.notify_followers(
      @page_recording,
      title: "#{@page.title} has news",
      body: "Something new is up on this page.",
      url: page_path(@page),
      event_key: params[:event_key].presence || "dummy-#{Time.current.to_i}",
      actor: current_user,
      deliver_later: false
    )

    redirect_to page_path(@page), notice: "Pinged everyone following this page."
  rescue RecordingStudioFollowable::NotAuthorized
    redirect_to pages_path, alert: "You don’t have access to that page."
  end

  private

  def pages_in_current_root
    root = current_follow_root
    return Page.none if root.blank?

    ids = RecordingStudio::Recording.where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
                                    .where(root_recording: root, recordable_type: "Page")
                                    .pluck(:recordable_id)
    Page.where(id: ids).order(:title)
  end

  def page_recording_for(page)
    RecordingStudio::Recording.where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
                              .find_by(recordable: page)
  end

  def current_follow_root
    return unless respond_to?(:current_root_recording, true)

    send(:current_root_recording)
  end

  def can_view?(recording)
    RecordingStudioAccessible.authorized?(actor: current_user, recording: recording, role: :view)
  end

  def following_page?
    return false if @follow_root.blank? || @page_recording.blank?
    return false unless can_view?(@follow_root)

    RecordingStudioFollowable::FollowQuery.active_for(root: @follow_root, target: @page_recording).present?
  end
end
