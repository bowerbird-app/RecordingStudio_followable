# frozen_string_literal: true

require "test_helper"

class CapabilitiesTest < Minitest::Test
  def test_followable_include_is_core_include_for
    mod = RecordingStudio::Capabilities::Followable.to
    assert_kind_of Module, mod
  end

  def test_follow_parent_include_is_core_include_for
    mod = RecordingStudio::Capabilities::FollowParent.to
    assert_kind_of Module, mod
  end

  def test_public_facade_exposes_follow_services
    %i[follow unfollow follows followers notify_followers].each do |name|
      assert_respond_to RecordingStudioFollowable, name
    end
  end

  def test_notify_followers_is_not_an_api_action
    skip "RecordingStudioApi is not loaded" unless defined?(RecordingStudioApi)

    refute RecordingStudioApi.capability_action(:notify_followers)
  end
end
