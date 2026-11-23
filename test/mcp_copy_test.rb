# frozen_string_literal: true

require "test_helper"

class McpCopyTest < Minitest::Test
  FORBIDDEN = [
    "RecordingStudio::", "Access", "Accessible", ":edit", ":view", "permission", "role",
    "Admin", "staff", "View"
  ].freeze
  GENERIC_NAMES = %w[capability_action list show create update delete notify_followers].freeze
  PER_TYPE_NAMES = %w[follow_page unfollow_page follow_workspace list_followers follow_press_center].freeze

  def test_tool_names_are_the_follow_actions
    assert_equal %w[follow unfollow followers follows], RecordingStudioFollowable::McpCopy.tool_names
    GENERIC_NAMES.each { |name| refute_includes RecordingStudioFollowable::McpCopy.tool_names, name }
    PER_TYPE_NAMES.each { |name| refute_includes RecordingStudioFollowable::McpCopy.tool_names, name }
    RecordingStudioFollowable::McpCopy.tool_names.each do |name|
      assert_match(/\A[a-z][a-z0-9_]*\z/, name)
      refute_includes name, "::"
    end
  end

  def test_register_is_a_no_op_when_mcp_is_not_loaded
    RecordingStudioFollowable::McpCopy.stub(:mcp_available?, false) do
      assert_nil RecordingStudioFollowable::McpCopy.register!
    end
  end

  def test_register_declares_named_tools_and_not_generic_names
    fake = RecordingMcp.new

    RecordingStudioFollowable::McpCopy.stub(:mcp_available?, true) do
      RecordingStudioFollowable::McpCopy.stub(:mcp, fake) do
        RecordingStudioFollowable::McpCopy.register!
        RecordingStudioFollowable::McpCopy.register!
      end
    end

    assert_equal RecordingStudioFollowable::McpCopy.tool_names, fake.tools.keys
    assert_equal RecordingStudioFollowable::McpCopy.tool_names.size * 2, fake.calls
    RecordingStudioFollowable::McpCopy::ACTIONS.each do |action|
      tool = fake.tools.fetch(action.to_s)
      assert_equal action, tool[:action]
      refute tool.key?(:type)
      refute tool.key?(:operation)
      refute tool.key?(:endpoint)
      assert_equal RecordingStudioFollowable::McpCopy.title_for(action), tool[:title]
      assert_equal RecordingStudioFollowable::McpCopy.description_for(action), tool[:description]
      assert_equal RecordingStudioFollowable::McpCopy.protocol_input(action), tool[:input]
      assert_equal RecordingStudioFollowable::McpCopy::OUTPUTS.fetch(action), tool[:output]
      assert_equal %w[type id], tool[:input].keys
      FORBIDDEN.each do |phrase|
        refute_includes tool[:description], phrase
        tool[:input].each_value { |field| refute_includes field.fetch(:description), phrase }
      end
    end

    follow = fake.tools.fetch("follow")
    assert_includes follow[:description], "Pass root_id"
    assert_includes follow[:description], "must already exist"
    assert_includes follow[:description], "cannot follow a follow"
    unfollow = fake.tools.fetch("unfollow")
    assert_includes unfollow[:description], "unfollowed true"
    followers = fake.tools.fetch("followers")
    assert_includes followers[:description], "list is empty"
    follows = fake.tools.fetch("follows")
    assert_includes follows[:description], "Run this on the workspace"
    assert_includes follows[:description], "must already exist"
    assert_equal RecordingStudioFollowable::Api::FOLLOWS_DESCRIPTION, follows[:description]
  end

  def test_named_tool_copy_stays_shared_when_openapi_is_overridden
    RecordingStudioFollowable::Api.override_openapi(
      type: "Page",
      action: :follow,
      title: "Follow this page",
      description: "Follow this page from a workspace."
    )
    fake = RecordingMcp.new

    RecordingStudioFollowable::McpCopy.stub(:mcp_available?, true) do
      RecordingStudioFollowable::McpCopy.stub(:mcp, fake) do
        RecordingStudioFollowable::McpCopy.register!
      end
    end

    follow = fake.tools.fetch("follow")
    shared = RecordingStudioFollowable::Api::FOLLOWABLE_ACTION_SPECS.find { |spec| spec.fetch(:name) == :follow }
    assert_equal shared.fetch(:title), follow[:title]
    assert_equal shared.fetch(:description), follow[:description]
    page = RecordingStudioFollowable::Api.openapi_for(type: "Page", action: :follow)
    assert_equal "Follow this page", page.fetch(:title)
    assert_equal "Follow this page from a workspace.", page.fetch(:description)
  ensure
    RecordingStudioFollowable::Api::OpenapiOverrides.reset!
  end

  def test_gemspec_does_not_depend_on_recording_studio_mcp
    gemspec = File.read(File.expand_path("../recording_studio_followable.gemspec", __dir__))
    api = File.read(File.expand_path("../lib/recording_studio_followable/api.rb", __dir__))

    refute_includes gemspec, "recording_studio_mcp"
    refute_includes api, 'require "recording_studio_mcp"'
    assert_includes api, "McpCopy.register!"
  end

  class RecordingMcp
    attr_reader :tools, :calls

    def initialize
      @tools = {}
      @calls = 0
    end

    def register_tool(**registration)
      @calls += 1
      @tools[registration.fetch(:name)] = registration
    end
  end
end
