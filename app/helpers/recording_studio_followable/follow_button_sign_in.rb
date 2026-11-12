# frozen_string_literal: true

module RecordingStudioFollowable
  module FollowButtonSignIn
    private

    def follow_sign_in_url(target, embedded:, appearance:)
      token = FollowIntent.issue(follow_intent_request(target, embedded:, appearance:))
      follow_sign_in_route(intent: token)
    end

    def follow_intent_request(target, embedded:, appearance:)
      FollowIntent::Request.new(
        target_id: target.id,
        page: follow_return_path,
        parent_url: embedded ? follow_parent_url : nil,
        button: appearance.carry,
        host: request.host,
        allowed_origins: RecordingStudioFollowable.configuration.allowed_return_origins
      )
    end

    def follow_sign_in_route(query)
      if respond_to?(:recording_studio_followable)
        recording_studio_followable.follow_sign_in_path(query)
      else
        follow_sign_in_path(query)
      end
    end

    def follow_return_path
      return unless respond_to?(:request) && request.respond_to?(:fullpath)

      request.fullpath
    end

    def follow_parent_url
      return unless follow_request_embedded?
      return unless request.respond_to?(:referrer)

      request.referrer
    end

    def follow_request_embedded?
      return false unless respond_to?(:request) && request.respond_to?(:headers)

      request.headers["Sec-Fetch-Dest"].to_s == "iframe"
    end
  end
end
