# frozen_string_literal: true

require "test_helper"

class RecordingStudioFollowableTest < Minitest::Test
  def test_version_matches_release
    assert_equal "0.2.0", ::RecordingStudioFollowable::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioFollowable::Engine
  end

  def test_gemspec_pins_recording_studio_6_3
    gemspec = File.read(File.expand_path("../recording_studio_followable.gemspec", __dir__))

    assert_includes gemspec, 'spec.add_dependency "recording_studio", ">= 6.3.0"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_notifications", "~> 0.14.9"'
  end

  def test_gemspec_excludes_cursor_config
    spec = Gem::Specification.load(File.expand_path("../recording_studio_followable.gemspec", __dir__))
    cursor_files = spec.files.select { |path| path == ".cursor" || path.split("/").include?(".cursor") }

    assert_empty cursor_files, "gemspec must not package .cursor/ (got #{cursor_files.inspect})"
  end

  def test_cursor_environment_is_repo_managed_without_snapshot
    path = File.expand_path("../.cursor/environment.json", __dir__)
    json = JSON.parse(File.read(path))

    assert_equal "recording-studio-followable", json["name"]
    assert_equal ".cursor/install.sh", json["install"]
    assert_equal ".cursor/start.sh", json["start"]
    refute json.key?("snapshot"), "snapshot pins a Personal build and skips install"
    refute json.key?("agentCanUpdateSnapshot")
  end

  def test_cursor_install_still_fetches_skills
    install_script = File.read(File.expand_path("../.cursor/install.sh", __dir__))

    assert_includes install_script, "fetch-skills.sh"
  end

  def test_dummy_gemfile_pins_verified_6x_github_tags
    gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio", tag: "v6.6.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.27.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.12.3"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_notifications", tag: "v0.14.9"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_root_switchable", tag: "v0.14.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.7.3"'
    assert_includes gemfile, 'github: "bowerbird-app/flatpack", tag: "v0.1.341"'
    refute_includes gemfile, 'tag: "v4.7.1"'
    refute_includes gemfile, "recording_studio/v3.0.0"
  end

  def test_dummy_schema_includes_accessible_depends_on_recording_id
    schema = File.read(File.expand_path("dummy/db/schema.rb", __dir__))
    migration = File.read(
      File.expand_path(
        "dummy/db/migrate/20260911024811_add_depends_on_recording_id_to_recording_studio_accesses.rb",
        __dir__
      )
    )

    assert_includes schema, 't.uuid "depends_on_recording_id"'
    assert_includes schema, "index_recording_studio_accesses_on_depends_on_recording_id"
    assert_includes migration, "add_column :recording_studio_accesses, :depends_on_recording_id, :uuid"
    assert_includes schema, 'create_table "recording_studio_access_invitations"'
    assert_includes schema, "idx_rs_access_invitations_token_digest"
    invitation_migration = File.read(
      File.expand_path(
        "dummy/db/migrate/20261001000011_create_recording_studio_access_invitations.rb",
        __dir__
      )
    )
    assert_includes invitation_migration, "create_table :recording_studio_access_invitations"
    assert_includes schema, 't.string "role", default: "view", null: false'
    refute_includes schema, 't.integer "role", default: 0, null: false'
    role_migration = Dir.glob(
      File.expand_path("dummy/db/migrate/*_change_recording_studio_accesses_role_to_string.rb", __dir__)
    ).max
    assert role_migration, "expected role-column migration in dummy db/migrate"
    assert_includes File.read(role_migration), "change_column :recording_studio_accesses, :role, :string"

    assert_includes schema, 'create_table "recording_studio_access_constraints"'
    assert_includes schema, 'create_table "recording_studio_access_rules"'
    assert_includes schema, "index_recording_studio_access_constraints_on_action"
    assert_includes schema, "index_recording_studio_access_rules_on_action"
    constraint_migration = Dir.glob(
      File.expand_path("dummy/db/migrate/*_create_recording_studio_access_constraints.rb", __dir__)
    ).max
    rule_migration = Dir.glob(
      File.expand_path("dummy/db/migrate/*_create_recording_studio_access_rules.rb", __dir__)
    ).max
    assert constraint_migration, "expected access constraints migration in dummy db/migrate"
    assert rule_migration, "expected access rules migration in dummy db/migrate"
    assert_includes File.read(constraint_migration), "create_table :recording_studio_access_constraints"
    assert_includes File.read(rule_migration), "create_table :recording_studio_access_rules"
  end

  def test_template_does_not_ship_copied_core_hooks_or_base_service
    refute File.exist?(File.expand_path("../lib/recording_studio_followable/hooks.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_followable/services/base_service.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_followable/services/example_service.rb", __dir__))
  end

  def test_addon_does_not_ship_the_template_example_capability
    refute File.exist?(File.expand_path("../lib/recording_studio_followable/capabilities/example.rb", __dir__))
    refute defined?(RecordingStudio::Capabilities::Example)
  end

  def test_dummy_app_uses_recording_studio_default_layout
    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)

    refute_includes controller_source, "UsesDefaultLayout"
    assert_includes controller_source, "RecordingStudio::DEFAULT_LAYOUT"
    assert_includes controller_source, "devise_controller? ? \"application\""
    refute_includes controller_source, "flat_pack_sidebar"
    refute File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__))
    refute File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__))
  end

  def test_dummy_login_layout_keeps_flatpack_assets_without_tight_main_offset
    application_layout = File.read(File.expand_path("dummy/app/views/layouts/application.html.erb", __dir__))

    assert_includes application_layout, '<html data-theme="rounded">'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/rich_text"'
    assert_includes application_layout, "javascript_importmap_tags"
    assert_includes application_layout, "min-h-screen"
    refute_includes application_layout, "mt-28"
    refute_includes application_layout, "flat_pack_sidebar"
  end

  def test_dummy_tailwind_keeps_flatpack_theme_selection_in_flatpack
    tailwind_source = File.read(File.expand_path("dummy/app/assets/tailwind/application.css", __dir__))

    assert_includes tailwind_source, "../../../vendor/engines/flat_pack/app/components"
    assert_includes tailwind_source, "../../../vendor/engines/recording_studio/app/views"
    refute_includes tailwind_source, "vendor/bundle/**/flatpack/app/components"
    refute_includes tailwind_source, "recordingstudio-*"
    refute_includes tailwind_source, "@theme"
    refute_includes tailwind_source, ":root {"
    refute_includes tailwind_source, "--color-fp-primary"

    head_partial = File.read(
      File.expand_path("dummy/app/views/recording_studio/_default_layout_head.html.erb", __dir__)
    )
    assert_includes head_partial, 'stylesheet_link_tag "flat_pack/application"'

    rake_task = File.read(File.expand_path("dummy/lib/tasks/tailwindcss.rake", __dir__))
    assert_includes rake_task, "FlatPack::Engine.root"
    assert_includes rake_task, "RecordingStudio::Engine.root"
    assert_includes rake_task, "tailwindcss:link_engine_sources"
  end

  def test_recording_studio_keeps_strict_recordable_declarations_enabled
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "config.require_recordable_declarations = true"
    assert_includes initializer_source, "RecordingStudioFollowable::Follow"
    refute_includes initializer_source, "config.include_children"
    refute_includes initializer_source, "config.features."
    refute_includes initializer_source, "v3"
  end

  def test_dummy_readme_explains_dummy_app_purpose
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "This Rails app exists to prove `recording_studio_followable` boots"
    assert_includes readme_source, "/recording_studio"
    assert_includes readme_source, "redirects to `/`"
    refute_includes readme_source, "flat_pack_sidebar"
  end

  def test_product_readme_describes_followable_without_invented_api
    readme = File.read(File.expand_path("../README.md", __dir__))

    assert_includes readme, "recording_studio_followable"
    assert_includes readme, "notify_followers"
    assert_includes readme, "generate recording_studio_followable:install"
    refute_includes readme, "coming soon"
    refute_includes readme, "internal template"
    refute_includes readme, "ExampleService"
    refute_includes readme, "recording_studio/v3.0.0"
  end

  def test_dummy_drops_removed_card_style_and_view_component_advisory
    home = File.read(File.expand_path("dummy/app/views/home/index.html.erb", __dir__))
    login = File.read(File.expand_path("dummy/app/views/devise/sessions/new.html.erb", __dir__))
    audit = File.read(File.expand_path("dummy/config/bundler-audit.yml", __dir__))
    installing = File.read(File.expand_path("../docs/gem_template/INSTALLING.md", __dir__))

    refute_match(/FlatPack::Card::Component\.new\([^)]*style:/, home)
    refute_match(/FlatPack::Card::Component\.new\([^)]*style:/, login)
    refute_includes audit, "GHSA-8qw7-6phv-7q6p"
    refute_includes installing, "flatpack/app/components"
    assert_includes installing, "bin/rails generate flat_pack:install"

    importmap = File.read(File.expand_path("dummy/config/importmap.rb", __dir__))
    stimulus_loader = File.read(File.expand_path("dummy/app/javascript/controllers/index.js", __dir__))
    refute_includes importmap, "recording_studio_root_switchable"
    refute_includes stimulus_loader, "recording_studio_root_switchable"
    copied_root_switch = File.expand_path(
      "dummy/app/views/recording_studio_root_switchable/root_switches/show.html.erb",
      __dir__
    )
    refute File.exist?(copied_root_switch)
  end

  def test_dummy_root_switch_dropdown_renders_rows_on_flatpack
    helper = File.read(File.expand_path("dummy/app/helpers/application_helper.rb", __dir__))

    assert_includes helper, "recording_studio_root_switch_dropdown"
    refute_includes helper, "recording_studio_root_switch_menu_rows"
    refute_includes helper, "class_eval"
    refute_includes helper, "prepend"
  end

  def test_dummy_home_page_uses_followable_title_only
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    refute_includes view_source, 'title: "Followable"'
    assert_includes view_source, 'title: "Keep an eye on a page"'
    assert_includes view_source, "follow_button("
    assert_includes view_source, "FlatPack::Card::Component"
    assert_includes view_source, "dummy_page_nav"
    refute_includes view_source, 'title: "Template Demo"'
    refute_includes view_source, "FlatPack::Breadcrumb::Component"
  end

  def test_engine_following_page_keeps_one_heading
    view_path = File.expand_path("../app/views/recording_studio_followable/follows/index.html.erb", __dir__)
    view_source = File.read(view_path)

    refute File.exist?(File.expand_path("dummy/app/views/follows/index.html.erb", __dir__))
    refute File.exist?(File.expand_path("dummy/app/controllers/follows_controller.rb", __dir__))
    assert_includes view_source, "recording_studio_followable.follows.title"
    refute_includes view_source, "Pages this workspace is watching."
    rows = File.read(File.expand_path("../app/views/recording_studio_followable/follows/_rows.html.erb", __dir__))
    assert_includes rows, "follow_target_url("
    assert_includes rows, "follow_button("
    assert_includes rows, "FlatPack::List::Component"
    assert_includes rows, "FlatPack::List::Item"
    assert_includes rows, "FlatPack::PaginationInfinite::Component"
  end

  def test_dummy_does_not_ship_template_starter_docs
    refute File.exist?(File.expand_path("dummy/app/controllers/docs_controller.rb", __dir__))
    assert_empty Dir[File.expand_path("dummy/app/views/docs/**/*", __dir__)]
  end

  def test_engine_does_not_ship_a_home_view
    view_path = File.expand_path("../app/views/recording_studio_followable/home/index.html.erb", __dir__)

    refute File.exist?(view_path)
  end
end
