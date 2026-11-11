# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class FollowFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.find_or_create_by!(email: "admin@admin.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    sign_in @admin
    load Rails.root.join("db/seeds.rb")
    @page = Page.find_by!(title: "Getting Started")
    @page_recording = RecordingStudio::Recording.find_by!(recordable: @page)
    @client = RecordingStudio.root_recording_for(Workspace.find_by!(name: "Client Workspace"))
  end

  test "home shows a follow button" do
    get root_path

    assert_response :success
    assert_includes @response.body, "Follow"
    assert_includes @response.body, "Keep an eye on a page"
    refute_match %r{<h1[^>]*>Followable</h1>}, @response.body
    assert_equal 1, @response.body.scan(/<h1[\s>]/i).length
  end

  test "following a page from the current workspace lists it and can ping the inbox" do
    switch_to_client_workspace

    post main_app.follows_path, params: { root_id: @client.id, target_id: @page_recording.id }
    assert_response :redirect
    follow_redirect!

    get main_app.follows_path
    assert_response :success
    assert_includes @response.body, "Getting Started"
    assert_equal 1, @response.body.scan(/<h1[\s>]/i).length

    post main_app.notify_followers_page_path(@page), params: { event_key: "flow-test" }
    follow_redirect!

    get "/notifications"
    assert_response :success
    assert_includes @response.body, "Getting Started has news"
  end

  private

  def switch_to_client_workspace
    return unless defined?(RecordingStudioRootSwitchable)

    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: @client.id,
        return_to: "/"
      }
    }
    assert_response :redirect
    follow_redirect!
  end
end
