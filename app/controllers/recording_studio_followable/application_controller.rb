# frozen_string_literal: true

module RecordingStudioFollowable
  parent_controller = defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base

  class ApplicationController < parent_controller
    include RecordingStudio::ControllerLayout

    recording_studio_layout { RecordingStudioFollowable.configuration.layout }

    protect_from_forgery with: :exception
  end
end
