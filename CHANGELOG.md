# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Config loading no longer uses empty `rescue` bodies, so RuboCop `Lint/SuppressedException` stays clean while missing host config still boots.
- The install initializer calls `RecordingStudioFollowable.configure` without an empty block.

## [0.1.0] - 2026-11-11

### Added
- Initial `recording_studio_followable` engine copied from RecordingStudio_gem_template and renamed.
- Dummy host app for Recording Studio, Devise, and FlatPack wiring.

### Notes
- Follow features are coming soon. This version does not ship a follow API, models, or public helpers.

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_followable/releases/tag/v0.1.0
