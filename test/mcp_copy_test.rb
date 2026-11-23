# frozen_string_literal: true

require "test_helper"

class McpCopyTest < Minitest::Test
  FORBIDDEN = [
    "RecordingStudio::", "Access", "Accessible", ":edit", ":view", "permission", "role",
    "Admin", "staff", "View"
  ].freeze
  TYPELESS_NAMES = RecordingStudioFollowable::McpCopy::TYPELESS_NAMES
  GENERIC_NAMES = %w[capability_action list show create update delete notify_followers].freeze
  PAGE_NAMES = %w[follow_page unfollow_page followers_page].freeze

  def test_tool_names_follow_enabled_types_and_skip_typeless_names
    with_follow_types do
      names = RecordingStudioFollowable::McpCopy.tool_names

      assert_equal PAGE_NAMES, names
      (TYPELESS_NAMES + GENERIC_NAMES).each { |name| refute_includes names, name }
      names.each do |name|
        assert_match(/\A[a-z][a-z0-9_]*\z/, name)
        refute_includes name, "::"
      end
    end
  end

  def test_tool_name_uses_the_api_public_name
    with_follow_types do
      assert_equal "follow_page", RecordingStudioFollowable::McpCopy.tool_name(:follow, "Page")
      assert_equal "follow_press_center",
                   RecordingStudioFollowable::McpCopy.tool_name(:follow, "RecordingStudioPressCenters::PressCenter")
    end
  end

  def test_register_is_a_no_op_when_mcp_is_not_loaded
    RecordingStudioFollowable::McpCopy.stub(:mcp_available?, false) do
      assert_nil RecordingStudioFollowable::McpCopy.register!
    end
  end

  def test_register_declares_per_type_tools_and_not_typeless_names
    fake = RecordingMcp.new
    register_twice(fake)

    assert_equal PAGE_NAMES, fake.tools.keys
    assert_equal fake.tools.size, fake.calls
    TYPELESS_NAMES.each { |name| refute fake.tools.key?(name) }
    assert_page_follow fake.tools.fetch("follow_page")
    assert_page_unfollow fake.tools.fetch("unfollow_page")
    assert_page_followers fake.tools.fetch("followers_page")
    assert_copy_avoids_forbidden_words fake
  end

  def test_follow_recordable_and_follow_parent_roots_get_no_tools
    names = with_follow_types(followable: ["Page", "RecordingStudioFollowable::Follow"]) do
      RecordingStudioFollowable::McpCopy.tool_names
    end

    assert_equal PAGE_NAMES, names
    refute_includes names, "follow_follow"
    refute_includes names, "follows_workspace"
    refute_includes names, "followers_follow"
  end

  def test_register_skips_a_name_another_gem_already_owns
    fake = RecordingMcp.new
    owned = { name: "follow_press_center", type: "RecordingStudioPressCenters::PressCenter", action: :follow,
              description: "Press Centers copy" }
    fake.tools["follow_press_center"] = owned

    with_follow_types(followable: ["Page", "RecordingStudioPressCenters::PressCenter"]) do
      RecordingStudioFollowable::McpCopy.stub(:mcp_available?, true) do
        RecordingStudioFollowable::McpCopy.stub(:mcp, fake) do
          RecordingStudioFollowable::McpCopy.register!
        end
      end
    end

    assert_same owned, fake.tools.fetch("follow_press_center")
    assert fake.tools.key?("followers_press_center")
    assert fake.tools.key?("unfollow_press_center")
    assert fake.tools.key?("follow_page")
    refute fake.tools.key?("follow")
  end

  def test_named_tool_copy_uses_the_openapi_override_for_that_type
    RecordingStudioFollowable::Api.override_openapi(
      type: "Page",
      action: :follow,
      title: "Follow this page",
      description: "Follow this page from a workspace."
    )
    fake = RecordingMcp.new

    with_follow_types do
      RecordingStudioFollowable::McpCopy.stub(:mcp_available?, true) do
        RecordingStudioFollowable::McpCopy.stub(:mcp, fake) do
          RecordingStudioFollowable::McpCopy.register!
        end
      end
    end

    follow = fake.tools.fetch("follow_page")
    assert_equal "Follow this page", follow[:title]
    assert_equal "Follow this page from a workspace.", follow[:description]
    page = RecordingStudioFollowable::Api.openapi_for(type: "Page", action: :follow)
    assert_equal "Follow this page", page.fetch(:title)
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

  private

  def with_follow_types(followable: ["Page"], &)
    config = RecordingStudio.configuration
    lookup = lambda do |capability|
      capability.to_sym == :followable ? followable : []
    end
    config.stub(:enabled_recordable_types_for, lookup, &)
  end

  def register_twice(fake)
    with_follow_types do
      RecordingStudioFollowable::McpCopy.stub(:mcp_available?, true) do
        RecordingStudioFollowable::McpCopy.stub(:mcp, fake) do
          RecordingStudioFollowable::McpCopy.register!
          RecordingStudioFollowable::McpCopy.register!
        end
      end
    end
  end

  def assert_page_follow(follow)
    assert_equal :follow, follow[:action]
    assert_equal "Page", follow[:type]
    assert_equal "Follow", follow[:title]
    assert_includes follow[:description], "Pass root_id"
    assert_includes follow[:description], "must already exist"
    assert_includes follow[:description], "cannot follow a follow"
    assert_equal %w[id root_id], follow[:input].keys
    refute follow[:input].key?("type")
  end

  def assert_page_unfollow(unfollow)
    assert_equal "Page", unfollow[:type]
    assert_includes unfollow[:description], "unfollowed true"
  end

  def assert_page_followers(followers)
    assert_equal "Page", followers[:type]
    assert_includes followers[:description], "list is empty"
    assert_equal %w[id], followers[:input].keys
  end

  def assert_copy_avoids_forbidden_words(fake)
    fake.tools.each_value do |tool|
      FORBIDDEN.each do |phrase|
        refute_includes tool[:description], phrase
        tool[:input].each_value { |field| refute_includes field.fetch(:description), phrase }
      end
    end
  end

  class RecordingMcp
    attr_reader :tools, :calls

    def initialize
      @tools = {}
      @calls = 0
    end

    def configuration
      self
    end

    def tool(name)
      @tools[name]
    end

    def register_tool(**registration)
      @calls += 1
      @tools[registration.fetch(:name)] = registration
    end
  end
end
