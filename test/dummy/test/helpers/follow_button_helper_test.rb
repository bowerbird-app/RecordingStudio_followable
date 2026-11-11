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
    load Rails.root.join("db/seeds.rb")
    @page = Page.find_by!(title: "Getting Started")
    @page_recording = RecordingStudio::Recording.find_by!(recordable: @page)
    @client = RecordingStudio.root_recording_for(Workspace.find_by!(name: "Client Workspace"))
  end

  teardown do
    Current.actor = nil
  end

  test "follow_button renders Follow when the root is not following" do
    html = follow_button(@page_recording, root: @client, actor: @admin)

    assert_includes html, "Follow"
    assert_includes html, "plus-circle"
    refute_includes html, "Unfollow"
  end

  test "follow_button renders Following and Unfollow when the root is following" do
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @admin)
    html = follow_button(@page_recording, root: @client, actor: @admin)

    assert_includes html, "Following"
    assert_includes html, "check-circle"
    assert_includes html, "Unfollow"
    assert_includes html, "minus-circle"
  end

  test "follow_button is blank without view on the follow root" do
    stranger = User.find_or_create_by!(email: "stranger@example.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end

    assert_nil follow_button(@page_recording, root: @client, actor: stranger)
  end

  def current_user
    @admin
  end

  def current_root_recording
    @client
  end
end
