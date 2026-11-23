# frozen_string_literal: true

require "test_helper"

class FollowableMcpToolsTest < ActiveSupport::TestCase
  TYPELESS_NAMES = %w[follow unfollow followers follows capability_action notify_followers].freeze
  PAGE_NAMES = %w[follow_page unfollow_page followers_page].freeze

  test "per-type follow tools are listed and typeless names are not" do
    listed = RecordingStudioMcp::ToolSurface.for(api: :public).tool_definitions
    names = listed.map { |tool| tool.fetch(:name) }

    assert_equal PAGE_NAMES, RecordingStudioFollowable::McpCopy.tool_names
    RecordingStudioFollowable::McpCopy.tool_names.each do |name|
      assert_includes names, name
      assert_equal name, RecordingStudioMcp::ToolName.call("Page", action_for(name))
    end
    TYPELESS_NAMES.each { |name| refute_includes names, name }
    refute_includes names, "follows_workspace"
    refute names.any? { |name| name.end_with?("_follow") }

    by_name = listed.to_h { |tool| [ tool.fetch(:name), tool ] }
    follow = by_name.fetch("follow_page")
    assert_equal "Follow", follow.fetch(:title)
    assert_includes follow.fetch(:description), "Pass root_id"
    assert_includes follow.fetch(:description), "must already exist"
    refute_match(/\b(View|Admin|Access)\b/, follow.fetch(:description))
    follow_props = properties(follow)
    assert follow_props.key?("id")
    assert follow_props.key?("root_id")
    refute follow_props.key?("type")
  end

  private

    def properties(tool)
      tool.fetch(:inputSchema).fetch(:properties).transform_keys(&:to_s)
    end

    def action_for(name)
      name.delete_suffix("_page").to_sym
    end
end
