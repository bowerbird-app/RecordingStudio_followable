# Dummy app

This Rails app exists to prove `recording_studio_followable` boots in a host application.

## What it covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace plus seeded folder and page recordables
- Recording Studio default layout, FlatPack assets, and Tailwind source scanning
- Mounted `RecordingStudio::Engine` route behavior inside a host app
- Follow and unfollow a page from the open workspace
- List follows and ping followers into the Notifications inbox

## Quick start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Run those commands from the dummy app directory, not the repository root.

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful routes

- `/` - dummy app home page
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/users/sign_in` - Devise sign-in page
- `/up` - Rails health check
- `/recording_studio_followable/follows` - engine Following page for the open workspace (keyset pages, lazy Load more)
- `/pages` - pages in the open workspace
- `/notifications` - inbox from Recording Studio Notifications

Sign in as `admin@admin.com`, switch to Client Workspace, follow Getting Started, then ping followers. Alice, Bob, and Charlie share Client Workspace. Getting Started lives in Studio Workspace.
