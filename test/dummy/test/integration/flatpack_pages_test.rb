# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class FlatpackPagesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    user = User.find_or_create_by!(email: "flatpack-pages@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    sign_in user
  end

  test "signed-in dummy pages render after the flatpack bump" do
    [
      root_path,
      docs_install_path,
      docs_config_path,
      docs_recordable_types_path,
      docs_recordings_tree_path,
      docs_gem_views_path,
      docs_methods_path
    ].each do |path|
      get path

      assert_response :success, "expected #{path} to render"
    end
  end
end
