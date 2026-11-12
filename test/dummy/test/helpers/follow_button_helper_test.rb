# frozen_string_literal: true

require "test_helper"

class FollowButtonHelperTest < ActionView::TestCase
  include RecordingStudioFollowable::FollowButtonHelper

  setup do
    @admin = User.find_or_create_by!(email: "admin@admin.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    Current.actor = @admin
    @view_actor = @admin
    load Rails.root.join("db/seeds.rb")
    @page = Page.find_by!(title: "Getting Started")
    @page_recording = RecordingStudio::Recording.find_by!(recordable: @page)
    @client = RecordingStudio.root_recording_for(Workspace.find_by!(name: "Client Workspace"))
  end

  teardown do
    Current.actor = nil
    RecordingStudioFollowable.configuration.followed_url = nil
    RecordingStudioFollowable.configuration.button = nil
  end

  test "follow_button renders Follow when the root is not following" do
    html = follow_button(@page_recording, root: @client, actor: @admin)

    assert_includes html, "Follow"
    assert_includes html, "plus-circle"
    assert_includes html, 'data-fp-style="default"'
    refute_includes html, 'data-fp-style="primary"'
    refute_includes html, "Unfollow"
    refute_includes html, "follow_sign_in"
  end

  test "follow_button renders Following and Unfollow when the root is following" do
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @admin)
    html = follow_button(@page_recording, root: @client, actor: @admin)

    assert_includes html, "Following"
    assert_includes html, "check-circle"
    assert_includes html, 'data-fp-style="secondary"'
    assert_includes html, "Unfollow"
    assert_includes html, "minus-circle"
  end

  test "follow_button renders for a signed-out visitor on a public page" do
    @view_actor = nil
    Current.actor = nil
    html = follow_button(@page_recording)

    assert_includes html, "Follow"
    assert_includes html, "plus-circle"
    assert_includes html, 'data-fp-style="default"'
    assert_includes html, "follow_sign_in"
    assert_includes html, @page_recording.id
  end

  test "signed-out follow uses the follow look from config and from the call" do
    @view_actor = nil
    Current.actor = nil
    RecordingStudioFollowable.configuration.button = { follow: { style: :ghost, label: "Watch" } }
    html = follow_button(@page_recording)

    assert_includes html, "Watch"
    assert_includes html, 'data-fp-style="ghost"'
    assert_includes html, "plus-circle"
    assert_includes html, "follow_sign_in"

    html = follow_button(@page_recording, follow: { label: "Pin", icon: "check-circle" })

    assert_includes html, "Pin"
    assert_includes html, "check-circle"
    refute_includes html, "Watch"
    assert_includes html, 'data-fp-style="ghost"'
  end

  test "a per-call override is carried on the follow form and the unfollow link" do
    html = follow_button(
      @page_recording,
      root: @client,
      actor: @admin,
      follow: { style: :primary, label: "Mark" },
      following: { label: "Kept" }
    )

    assert_includes html, "Mark"
    assert_includes html, 'data-fp-style="primary"'
    assert_includes html, 'name="follow_button[follow][style]"'
    assert_includes html, 'value="primary"'
    assert_includes html, 'name="follow_button[follow][label]"'
    assert_includes html, 'value="Mark"'

    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @admin)
    html = follow_button(
      @page_recording,
      root: @client,
      actor: @admin,
      follow: { label: "Mark" },
      following: { label: "Kept", icon: "plus-circle" }
    )

    assert_includes html, "Kept"
    assert_includes html, "plus-circle"
    assert_includes CGI.unescape(html), "follow_button[follow][label]=Mark"
    assert_includes CGI.unescape(html), "follow_button[following][label]=Kept"
  end

  test "follow_button rejects an unknown setting and an unknown style" do
    assert_raises(ArgumentError) do
      follow_button(@page_recording, root: @client, actor: @admin, follow: { color: "red" })
    end
    assert_raises(ArgumentError) do
      follow_button(@page_recording, root: @client, actor: @admin, following: { style: :nope })
    end
  end

  test "follow_button is blank without view on the follow root" do
    stranger = User.find_or_create_by!(email: "stranger@example.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end

    assert_nil follow_button(@page_recording, root: @client, actor: stranger)
  end

  test "follow_target_url uses polymorphic_path on the recordable" do
    assert_equal page_path(@page), follow_target_url(@page_recording)
  end

  test "follow_target_url uses config.followed_url when set" do
    RecordingStudioFollowable.configuration.followed_url = ->(_recording) { "/custom-page" }

    assert_equal "/custom-page", follow_target_url(@page_recording)
  end

  def current_user
    @view_actor
  end

  def current_root_recording
    @client
  end
end
