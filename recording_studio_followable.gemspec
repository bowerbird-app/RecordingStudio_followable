# frozen_string_literal: true

require_relative "lib/recording_studio_followable/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_followable"
  spec.version     = RecordingStudioFollowable::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_followable"
  spec.summary     = "Recording Studio addon for following recordings"
  spec.description = "Follow items from a workspace and notify people with access to that workspace."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/RecordingStudio_followable"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/RecordingStudio_followable/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].reject do |path|
      path == ".cursor" || path.start_with?(".cursor/")
    end
  end

  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", ">= 6.3.0"
  spec.add_dependency "recording_studio_accessible", "~> 0.18"
  spec.add_dependency "recording_studio_notifications", "~> 0.14.9"
  spec.add_dependency "recording_studio_trashable", ">= 0.12.0"
end
