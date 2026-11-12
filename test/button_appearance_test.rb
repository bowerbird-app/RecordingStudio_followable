# frozen_string_literal: true

require "test_helper"

class ButtonAppearanceTest < Minitest::Test
  def test_defaults_use_a_non_primary_follow_style
    resolved = RecordingStudioFollowable::ButtonAppearance.resolve(config: {})

    assert_equal :default, resolved.follow.style
    assert_equal "plus-circle", resolved.follow.icon
    assert_equal "Follow", resolved.follow.label
    assert_equal :secondary, resolved.following.style
    assert_equal "check-circle", resolved.following.icon
    assert_equal "Following", resolved.following.label
    assert_equal "Unfollow", resolved.unfollow_label
    assert_equal "minus-circle", resolved.unfollow_icon
    assert_empty resolved.carry
  end

  def test_config_and_per_call_merge_and_an_explicit_label_wins
    I18n.backend.store_translations(
      :en,
      recording_studio_followable: { follow_button: { follow: "Track", following: "Tracked" } }
    )
    resolved = RecordingStudioFollowable::ButtonAppearance.resolve(
      config: { follow: { style: :ghost, label: "Watch" }, following: { icon: "check-circle" } },
      follow: { label: "Pin" },
      following: { style: :primary }
    )

    assert_equal :ghost, resolved.follow.style
    assert_equal "Pin", resolved.follow.label
    assert_equal "plus-circle", resolved.follow.icon
    assert_equal :primary, resolved.following.style
    assert_equal "check-circle", resolved.following.icon
    assert_equal "Tracked", resolved.following.label
    assert_equal({ follow: { label: "Pin" }, following: { style: "primary" } }, resolved.carry)
  ensure
    I18n.backend.reload!
  end

  def test_translation_is_used_when_no_label_is_set
    I18n.backend.store_translations(
      :en,
      recording_studio_followable: { follow_button: { follow: "Track" } }
    )

    resolved = RecordingStudioFollowable::ButtonAppearance.resolve(config: {})

    assert_equal "Track", resolved.follow.label
  ensure
    I18n.backend.reload!
  end

  def test_icon_markup_is_rejected
    error = assert_raises(ArgumentError) do
      RecordingStudioFollowable::ButtonAppearance.parse({ follow: { icon: "<svg>" } })
    end

    assert_includes error.message, "icon must be a name"
  end

  def test_blank_label_is_rejected
    assert_raises(ArgumentError) do
      RecordingStudioFollowable::ButtonAppearance.parse({ follow: { label: "  " } })
    end
  end
end
