# Recording Studio Followable

`recording_studio_followable` is a Recording Studio addon for following recordings.

Follow features are coming soon. This release is the renamed engine, dummy host app, and install generator. It does not expose a follow API yet.

## Install

Add the gem to the host app Gemfile:

```ruby
gem "recording_studio_followable", github: "bowerbird-app/RecordingStudio_followable"
```

Then:

```bash
bundle install
bin/rails generate recording_studio_followable:install
bin/rails generate recording_studio_followable:migrations
bin/rails db:migrate
```

The install generator mounts the engine and adds a host initializer. There are no follow migrations yet, so the migrations generator copies an empty set.

Do not add access rules in this gem. Accessible owns grants. This addon does not ship a staff UI.

## Dummy host app

`test/dummy` is a host app used to prove the engine boots with Recording Studio, Devise, and FlatPack. It is not the product.

Sign in at `/users/sign_in` with `admin@admin.com` / `Password`.

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

## Version

The gem version is `0.1.0`.
