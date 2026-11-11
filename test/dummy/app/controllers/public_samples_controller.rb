# frozen_string_literal: true

class PublicSamplesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def show
    @page = Page.find_by!(title: "Getting Started")
    @page_recording = page_recording_for(@page)
    raise ActiveRecord::RecordNotFound unless @page_recording
  end

  def embed; end

  private

  def page_recording_for(page)
    RecordingStudio::Recording.where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
                              .find_by(recordable: page)
  end
end
