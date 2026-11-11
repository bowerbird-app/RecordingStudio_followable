# frozen_string_literal: true

require "test_helper"

class ReturnToTest < Minitest::Test
  def test_relative_return_path_beats_an_offsite_parent
    url = RecordingStudioFollowable::ReturnTo.preferred(
      parent_url: "https://evil.test/phish",
      return_to: "/sample",
      canonical: "/pages/1",
      host: "follow.test",
      allowed_origins: []
    )

    assert_equal "/sample", url
  end

  def test_allowlisted_parent_is_the_return_url
    url = RecordingStudioFollowable::ReturnTo.preferred(
      parent_url: "https://press.test/story",
      return_to: "/sample",
      canonical: "/pages/1",
      host: "follow.test",
      allowed_origins: ["press.test"]
    )

    assert_equal "https://press.test/story", url
  end

  def test_protocol_relative_return_falls_through_to_the_canonical_path
    url = RecordingStudioFollowable::ReturnTo.preferred(
      parent_url: nil,
      return_to: "//evil.test",
      canonical: "/pages/1",
      host: "follow.test",
      allowed_origins: ["evil.test"]
    )

    assert_equal "/pages/1", url
  end
end
