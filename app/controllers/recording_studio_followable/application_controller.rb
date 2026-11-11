# frozen_string_literal: true

module RecordingStudioFollowable
  parent_controller = defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base

  class ApplicationController < parent_controller
    if defined?(::RecordingStudio::RootSwitchable::ControllerSupport)
      include ::RecordingStudio::RootSwitchable::ControllerSupport
    end

    protect_from_forgery with: :exception
  end
end
