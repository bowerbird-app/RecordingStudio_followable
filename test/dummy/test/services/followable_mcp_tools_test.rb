# frozen_string_literal: true

require "test_helper"

class FollowableMcpToolsTest < ActiveSupport::TestCase
  GENERIC_NAMES = %w[capability_action notify_followers].freeze
  PER_TYPE_NAMES = %w[follow_page unfollow_page follow_workspace list_followers follow_press_center].freeze

  test "named follow tools are listed and generic names are not" do
    listed = RecordingStudioMcp::ToolSurface.for(api: :public).tool_definitions
    names = listed.map { |tool| tool.fetch(:name) }

    RecordingStudioFollowable::McpCopy.tool_names.each do |name|
      assert_includes names, name
    end
    GENERIC_NAMES.each { |name| refute_includes names, name }
    PER_TYPE_NAMES.each { |name| refute_includes names, name }

    by_name = listed.to_h { |tool| [ tool.fetch(:name), tool ] }
    follow = by_name.fetch("follow")
    assert_includes follow.fetch(:description), "Pass root_id"
    assert_includes follow.fetch(:description), "must already exist"
    refute_match(/\b(View|Admin|Access)\b/, follow.fetch(:description))
    follow_props = properties(follow)
    assert follow_props.key?("type")
    assert follow_props.key?("id")
    assert follow_props.key?("root_id")

    follows = by_name.fetch("follows")
    assert_equal "Follows", follows.fetch(:title)
    assert_includes follows.fetch(:description), "Run this on the workspace"
    follows_props = properties(follows)
    assert follows_props.key?("type")
    assert follows_props.key?("id")
    refute follows_props.key?("root_id")
  end

  private

  def properties(tool)
    tool.fetch(:inputSchema).fetch(:properties).transform_keys(&:to_s)
  end
end
