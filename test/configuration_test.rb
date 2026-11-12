# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioFollowable::Configuration.new
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(allowed_parent_types: ["Site"])

    assert_equal ["Site"], @configuration.allowed_parent_types
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", allowed_parent_types: ["Folder"])

    refute_respond_to @configuration, :unknown_key
    assert_equal ["Folder"], @configuration.allowed_parent_types
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h

    @configuration.merge!(nil)

    assert_equal original[:allowed_parent_types], @configuration.allowed_parent_types
  end

  def test_initialize_defaults_parent_types_to_workspace
    configuration = RecordingStudioFollowable::Configuration.new

    assert_equal ["Workspace"], configuration.allowed_parent_types
    assert_nil configuration.followed_url
    assert_nil configuration.current_root
    assert_nil configuration.layout
    assert_equal 25, configuration.page_size
    assert_instance_of RecordingStudio::Hooks, configuration.hooks
  end

  def test_page_size_rejects_zero
    assert_raises(ArgumentError) { @configuration.page_size = 0 }
  end

  def test_resolve_current_root_calls_configured_proc
    root = Object.new
    @configuration.current_root = ->(context) { context == :ctl ? root : nil }

    assert_equal root, @configuration.resolve_current_root(:ctl)
    assert_nil @configuration.resolve_current_root(:other)
  end

  def test_merge_updates_followed_url
    resolver = ->(recording) { "/items/#{recording.id}" }
    @configuration.merge!(followed_url: resolver)

    assert_equal resolver, @configuration.followed_url
  end

  def test_merge_accepts_string_keys
    @configuration.merge!("allowed_parent_types" => ["Account"])

    assert_equal ["Account"], @configuration.allowed_parent_types
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioFollowable.configure

    assert_kind_of RecordingStudioFollowable::Configuration, RecordingStudioFollowable.configuration
  end

  def test_button_defaults_to_an_empty_override
    assert_equal({}, @configuration.button)
  end

  def test_button_stores_a_partial_override
    @configuration.button = { follow: { style: :primary, label: "Watch" } }

    assert_equal({ follow: { style: :primary, label: "Watch" } }, @configuration.button)
  end

  def test_button_rejects_an_unknown_state
    error = assert_raises(ArgumentError) { @configuration.button = { unfollow: { style: :ghost } } }

    assert_includes error.message, "unknown button state"
  end

  def test_button_rejects_an_unknown_setting
    error = assert_raises(ArgumentError) { @configuration.button = { follow: { color: "red" } } }

    assert_includes error.message, "unknown follow button setting"
  end

  def test_merge_updates_button
    @configuration.merge!(button: { following: { icon: "check-circle" } })

    assert_equal({ following: { icon: "check-circle" } }, @configuration.button)
  end

  def test_button_nil_clears_overrides
    @configuration.button = { follow: { style: :primary } }
    @configuration.button = nil

    assert_equal({}, @configuration.button)
  end
end
