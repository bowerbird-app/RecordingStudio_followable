# frozen_string_literal: true

require "test_helper"

class ApiOpenapiOverrideTest < Minitest::Test
  PRESS_CENTER = "RecordingStudioPressCenters::PressCenter"

  def teardown
    RecordingStudioFollowable::Api::OpenapiOverrides.reset!
  end

  def test_unset_type_keeps_shared_follow_copy
    copy = RecordingStudioFollowable::Api.openapi_for(type: PRESS_CENTER, action: :follow)

    assert_equal "Follow a recording", copy.fetch(:title)
    assert_equal "Create a follow from a workspace.", copy.fetch(:summary)
    assert_includes copy.fetch(:description), "POST /api/v1/{resource}/{id}/actions/follow"
    refute_equal RecordingStudioFollowable::McpCopy::Copy::DESCRIPTIONS.fetch(:follow), copy.fetch(:description)
  end

  def test_override_sets_one_type_and_leaves_other_types_and_actions_shared
    RecordingStudioFollowable::Api.override_openapi(
      type: PRESS_CENTER,
      action: :follow,
      title: "Follow press center",
      description: "Follow this press center from a workspace."
    )

    follow = RecordingStudioFollowable::Api.openapi_for(type: PRESS_CENTER, action: "follow")
    assert_equal "Follow press center", follow.fetch(:title)
    assert_equal "Follow this press center from a workspace.", follow.fetch(:description)
    assert_equal "Create a follow from a workspace.", follow.fetch(:summary)

    page = RecordingStudioFollowable::Api.openapi_for(type: "Page", action: :follow)
    assert_equal "Follow a recording", page.fetch(:title)
    assert_includes page.fetch(:description), "POST /api/v1/{resource}/{id}/actions/follow"

    followers = RecordingStudioFollowable::Api.openapi_for(type: PRESS_CENTER, action: :followers)
    assert_equal "List recording followers", followers.fetch(:title)
    assert_includes followers.fetch(:description), "GET /api/v1/{resource}/{id}/actions/followers"
  end

  def test_reset_restores_shared_copy
    RecordingStudioFollowable::Api.override_openapi(
      type: PRESS_CENTER,
      action: :unfollow,
      title: "Unfollow press center",
      description: "Stop following this press center from a workspace."
    )
    RecordingStudioFollowable::Api::OpenapiOverrides.reset!

    copy = RecordingStudioFollowable::Api.openapi_for(type: PRESS_CENTER, action: :unfollow)
    assert_equal "Unfollow a recording", copy.fetch(:title)
    assert_includes copy.fetch(:description), "POST /api/v1/{resource}/{id}/actions/unfollow"
  end

  def test_unknown_action_raises
    error = assert_raises(ArgumentError) do
      RecordingStudioFollowable::Api.override_openapi(
        type: PRESS_CENTER,
        action: :notify_followers,
        title: "Notify",
        description: "No"
      )
    end
    assert_equal "Unknown Followable action :notify_followers", error.message

    read_error = assert_raises(ArgumentError) do
      RecordingStudioFollowable::Api.openapi_for(type: PRESS_CENTER, action: :follows)
    end
    assert_equal "Unknown Followable action :follows", read_error.message
  end

  def test_missing_type_or_copy_raises
    assert_raises(ArgumentError) do
      RecordingStudioFollowable::Api.override_openapi(
        type: "",
        action: :follow,
        title: "Follow press center",
        description: "Follow this press center from a workspace."
      )
    end

    assert_raises(ArgumentError) do
      RecordingStudioFollowable::Api.override_openapi(
        type: PRESS_CENTER,
        action: :follow,
        title: nil,
        description: "Follow this press center from a workspace."
      )
    end
  end
end
