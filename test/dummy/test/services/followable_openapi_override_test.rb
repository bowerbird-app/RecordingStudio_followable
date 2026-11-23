# frozen_string_literal: true

require "test_helper"

class FollowableOpenapiOverrideTest < ActiveSupport::TestCase
  PRESS_CENTER = "RecordingStudioPressCenters::PressCenter"

  teardown do
    RecordingStudioFollowable::Api::OpenapiOverrides.reset!
  end

  test "registered actions keep shared copy until a type override is set" do
    %i[follow unfollow followers].each do |name|
      action = RecordingStudioApi.capability_action(name)
      copy = action.openapi_for(type: PRESS_CENTER, action: name)

      assert_equal action.openapi.fetch(:title), copy.fetch(:title)
      assert_equal action.openapi.fetch(:summary), copy.fetch(:summary)
      assert_equal action.openapi.fetch(:description), copy.fetch(:description)
    end

    RecordingStudioFollowable::Api.override_openapi(
      type: PRESS_CENTER,
      action: :follow,
      title: "Follow press center",
      description: "Follow this press center from a workspace."
    )

    follow = RecordingStudioApi.capability_action(:follow)
    overridden = follow.openapi_for(type: PRESS_CENTER, action: :follow)
    assert_equal "Follow press center", overridden.fetch(:title)
    assert_equal "Follow this press center from a workspace.", overridden.fetch(:description)
    assert_equal follow.openapi.fetch(:summary), overridden.fetch(:summary)
    assert_equal "Follow a recording", follow.openapi.fetch(:title)
    request_root = overridden.dig(:request_body, :content, :"application/json", :schema, :properties, :root_id)
    assert_includes request_root.fetch(:description), "404 not_found"

    page = follow.openapi_for(type: "Page", action: :follow)
    assert_equal "Follow a recording", page.fetch(:title)

    followers = RecordingStudioApi.capability_action(:followers).openapi_for(type: PRESS_CENTER, action: :followers)
    assert_equal "List recording followers", followers.fetch(:title)

    follows = RecordingStudioApi.capability_action(:follows).openapi_for(type: PRESS_CENTER, action: :follows)
    assert_equal "List follows stored on a workspace.", follows.fetch(:summary)
    assert_equal "List workspace follows", follows.fetch(:title)

    RecordingStudioFollowable::Api::OpenapiOverrides.reset!
    restored = follow.openapi_for(type: PRESS_CENTER, action: :follow)
    assert_equal "Follow a recording", restored.fetch(:title)
    assert_includes restored.fetch(:description), "POST /api/v1/{resource}/{id}/actions/follow"
  end
end
