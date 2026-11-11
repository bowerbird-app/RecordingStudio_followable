# Development notes

## Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 6.3 or newer (dummy GitHub tag `v6.6.0`)
- Accessible dummy tag `v0.27.0`
- Trashable dummy tag `v0.12.3`
- Notifications dummy tag `v0.14.9`
- Root Switchable dummy tag `v0.14.0`
- Metrics dummy tag `v0.7.3`
- FlatPack dummy tag `v0.1.341`

## Verification

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy host from `test/dummy`:

```bash
cd test/dummy
bin/dev
```
