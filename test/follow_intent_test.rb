# frozen_string_literal: true

require "test_helper"
require "active_support/message_verifier"
require "active_support/testing/time_helpers"

class FollowIntentTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def setup
    @app = Class.new do
      def message_verifier(_name)
        @message_verifier ||= ActiveSupport::MessageVerifier.new(
          "a" * 128,
          digest: "SHA256",
          serializer: JSON,
          url_safe: true
        )
      end
    end.new
  end

  def test_round_trip_keeps_the_target_and_drops_an_offsite_parent
    token = with_verifier { RecordingStudioFollowable::FollowIntent.issue(sample_request) }

    intent = with_verifier { RecordingStudioFollowable::FollowIntent.read(token) }

    assert_equal "target-1", intent.target_id
    assert_equal "/sample", intent.page
    assert_nil intent.parent_url
    assert_equal "Pin", intent.button.dig("follow", "label")
  end

  def test_expired_and_tampered_tokens_read_as_blank
    token = travel_to(Time.zone.local(2026, 11, 12, 12, 0, 0)) do
      with_verifier { RecordingStudioFollowable::FollowIntent.issue(sample_request(parent_url: nil, button: {})) }
    end

    expired = travel_to(Time.zone.local(2026, 11, 12, 12, 16, 0)) do
      with_verifier { RecordingStudioFollowable::FollowIntent.read(token) }
    end
    tampered = with_verifier { RecordingStudioFollowable::FollowIntent.read("#{token}x") }

    assert_nil expired
    assert_nil tampered
  end

  def with_verifier(&)
    Rails.stub(:application, @app, &)
  end

  def sample_request(parent_url: "https://evil.test/phish", button: { follow: { label: "Pin" } })
    RecordingStudioFollowable::FollowIntent::Request.new(
      target_id: "target-1",
      page: "/sample",
      parent_url: parent_url,
      button: button,
      host: "follow.test",
      allowed_origins: []
    )
  end
end
