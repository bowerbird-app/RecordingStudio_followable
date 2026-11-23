# frozen_string_literal: true

require "test_helper"
require "open3"

class ApiRegisterBootTest < ActiveSupport::TestCase
  FOLLOWABLE_ACTIONS = %i[follow unfollow followers follows].freeze
  MISSING_FOLLOW = "missing followable action follow"

  test "register_api runs before finisher_hook and actions exist after boot" do
    assert Rails.application.initialized?

    names = Rails.application.initializers.tsort.map(&:name)
    register_api = names.index("recording_studio_followable.register_api")
    prepare = names.index(:run_prepare_callbacks)
    finisher = names.index(:finisher_hook)

    assert register_api, "missing recording_studio_followable.register_api"
    assert prepare, "missing :run_prepare_callbacks"
    assert finisher, "missing :finisher_hook"
    assert_operator register_api, :<, prepare
    assert_operator prepare, :<, finisher

    FOLLOWABLE_ACTIONS.each do |name|
      assert RecordingStudioApi.capability_action(name), "public API missing #{name}"
    end
  end

  test "boot after_initialize sees followable actions, delayed register does not" do
    delayed = boot_dummy_subprocess(delay_register: true)

    refute_predicate delayed[:status], :success?
    assert_includes "#{delayed[:stdout]}\n#{delayed[:stderr]}", MISSING_FOLLOW

    current = boot_dummy_subprocess(delay_register: false)

    assert_predicate current[:status], :success?, current[:stderr]
    assert_includes current[:stdout], "BOOT_OK"
    refute_includes "#{current[:stdout]}\n#{current[:stderr]}", MISSING_FOLLOW
  end

  private

  def boot_dummy_subprocess(delay_register:)
    dummy_root = File.expand_path("../..", __dir__)
    script = <<~RUBY
      ENV["RAILS_ENV"] = "test"
      require "./config/application"
      Rails.application.config.after_initialize do
        missing = %i[follow unfollow followers follows].reject { |name| RecordingStudioApi.capability_action(name) }
        raise "missing followable action \#{missing.first}" if missing.any?

        print "BOOT_OK"
      end
      if #{delay_register}
        init = Rails.application.initializers.find do |initializer|
          initializer.name.to_s == "recording_studio_followable.register_api"
        end
        raise "missing register_api initializer" unless init

        init.instance_variable_set(:@block, proc {})
        Rails.application.config.after_initialize do
          RecordingStudioFollowable::Api.register!
        end
      end
      Rails.application.initialize!
    RUBY

    stdout, stderr, status = Open3.capture3(
      {
        "RAILS_ENV" => "test",
        "BUNDLE_GEMFILE" => File.join(dummy_root, "Gemfile"),
        "DISABLE_SPRING" => "1"
      },
      "bundle", "exec", "ruby", "-e", script,
      chdir: dummy_root
    )

    { stdout: stdout, stderr: stderr, status: status }
  end
end
