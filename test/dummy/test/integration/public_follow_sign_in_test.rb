# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PublicFollowSignInTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  FRAME = RecordingStudioUser::OtpCodeForm::FRAME_ID

  setup do
    Rails.cache.clear
    @admin = User.find_or_create_by!(email: "admin@admin.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    Current.actor = @admin
    load Rails.root.join("db/seeds.rb")
    @page = Page.find_by!(title: "Getting Started")
    @page_recording = RecordingStudio::Recording.find_by!(recordable: @page)
    @client = RecordingStudio.root_recording_for(Workspace.find_by!(name: "Client Workspace"))
    @alice = User.find_by!(email: "alice@example.com")
  end

  teardown do
    Current.actor = nil
    RecordingStudioFollowable.configuration.account_setup_url = nil
    Rails.cache.clear
  end

  test "signed-out visitors see Follow and an email step in a modal" do
    get public_sample_path

    assert_response :success
    assert_includes response.body, "Follow"
    assert_includes response.body, "plus-circle"
    assert_includes response.body, "data-modal-id="
    assert_includes response.body, 'name="email"'
    assert_includes response.body, "follow_sign_in"
  end

  test "an embedded public page opens sign-in in a new tab" do
    get public_sample_path, headers: { "Sec-Fetch-Dest" => "iframe" }

    assert_response :success
    assert_includes response.body, 'target="_blank"'
    assert_includes response.body, "follow_sign_in"
  end

  test "email code signs the visitor in and the finish post follows once" do
    get public_sample_path
    return_to = return_to_from(response.body)

    post recording_studio_user_otp_start_path,
         params: { email: @alice.email, return_to: return_to },
         headers: { "Turbo-Frame" => FRAME }
    assert_response :success
    assert_select "input[name=code]"
    assert_select "input[name=accept_terms]", count: 0

    post code_form_action(response.body),
         params: { code: otp_code },
         headers: { "Turbo-Frame" => FRAME }
    assert_response :success
    assert_includes response.body, "csrf_token"
    assert_includes response.body, "recording_studio_user:signed_in"

    assert_difference -> { follows_for_page }, 1 do
      post recording_studio_followable.follow_sign_in_path, params: { intent: intent_from(return_to) },
                                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_includes response.body, %(target="follow-button-#{@page_recording.id}-guest")
    assert_includes response.body, "Following"

    assert_no_difference -> { follows_for_page } do
      post recording_studio_followable.follow_sign_in_path, params: { intent: intent_from(return_to) },
                                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
  end

  test "a new address must accept terms before sign-in and does not follow without a workspace" do
    email = "new-#{SecureRandom.hex(4)}@example.com"
    get public_sample_path
    return_to = return_to_from(response.body)

    post recording_studio_user_otp_start_path,
         params: { email: email, return_to: return_to },
         headers: { "Turbo-Frame" => FRAME }
    assert_response :success
    assert_select "input[name=accept_terms]"

    code = otp_code
    post code_form_action(response.body),
         params: { code: code },
         headers: { "Turbo-Frame" => FRAME }
    assert_response :unprocessable_entity
    refute User.find_by!(email: email).confirmed?

    assert_no_difference -> { follows_for_page } do
      post code_form_action(response.body),
           params: { code: code, accept_terms: "1" },
           headers: { "Turbo-Frame" => FRAME }
      assert_response :success
      post recording_studio_followable.follow_sign_in_path, params: { intent: intent_from(return_to) }
    end

    assert_redirected_to recording_studio_followable.follow_sign_in_setup_path
    follow_redirect!
    assert_includes response.body, "Finish setting up your account first"
    assert User.find_by!(email: email).confirmed?
  end

  test "a host setup url redirects instead of the setup page" do
    RecordingStudioFollowable.configuration.account_setup_url = "/welcome"
    email = "setup-#{SecureRandom.hex(4)}@example.com"
    get public_sample_path
    return_to = return_to_from(response.body)

    post recording_studio_user_otp_start_path,
         params: { email: email, return_to: return_to },
         headers: { "Turbo-Frame" => FRAME }
    post code_form_action(response.body),
         params: { code: otp_code, accept_terms: "1" },
         headers: { "Turbo-Frame" => FRAME }

    assert_no_difference -> { follows_for_page } do
      post recording_studio_followable.follow_sign_in_path, params: { intent: intent_from(return_to) }
    end
    assert_redirected_to "/welcome"
  end

  test "a forged intent does not follow" do
    sign_in @alice
    before = follows_for_page

    post recording_studio_followable.follow_sign_in_path, params: { intent: "not-a-token" }

    assert_redirected_to "/"
    assert_equal before, follows_for_page
  end

  private

  def follows_for_page
    RecordingStudioFollowable::FollowQuery.active_for(root: @client, target: @page_recording).present? ? 1 : 0
  end

  def return_to_from(body)
    raw = body[/name="return_to" value="([^"]+)"/, 1]
    CGI.unescapeHTML(raw.to_s)
  end

  def intent_from(return_to)
    Rack::Utils.parse_query(URI.parse(return_to).query)["intent"]
  end

  def code_form_action(body)
    body[/action="([^"]*otp\/challenge)"/, 1]
  end

  def otp_code
    challenge = RecordingStudioUser::OtpChallenge.order(created_at: :desc).first
    RecordingStudioUser.otp_message(challenge.id).fetch(:body)[/\d{6}/]
  end
end
