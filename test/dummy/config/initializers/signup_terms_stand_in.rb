# frozen_string_literal: true

module RecordingStudioTermsAndConditions
  class NotLive < StandardError; end

  Document = Data.define(:title, :body)

  module Config
    module_function

    def app_name
      "Followable"
    end
  end

  module Gate
    module_function

    def root_for_signup(*)
      workspace = Workspace.find_by(name: "Client Workspace")
      return if workspace.blank?

      RecordingStudio.root_recording_for(workspace)
    end
  end

  module_function

  def pending_published_list(*)
    [Document.new(title: "House rules", body: "Be kind.")]
  end

  def accept!(*)
    true
  end

  def configuration
    Config
  end
end

module Dummy
  module SignupTermsHelper
    def recording_studio_terms_continue_notice(*)
      "House rules"
    end

    def recording_studio_terms_signup_root
      RecordingStudioTermsAndConditions::Gate.root_for_signup(self)
    end

    def recording_studio_terms_agree_actor
      nil
    end

    def continue_notice_document_words(*)
      "House rules".html_safe
    end

    def terms_document(*)
      nil
    end

    def privacy_document(*)
      nil
    end

    def continue_notice_modal(*)
      nil
    end
  end
end

Rails.application.config.to_prepare do
  next if defined?(RecordingStudioTermsAndConditions::ContinueNoticeHelper)

  RecordingStudioUser::ApplicationController.helper(Dummy::SignupTermsHelper)
end
