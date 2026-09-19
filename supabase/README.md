# Eightwise Supabase setup

The iOS app reads published vocabulary directly from Supabase's Data API. It does not require a separate Render service.

1. Create a dedicated Supabase project.
2. Apply `schema.sql` once.
3. Apply `seed.sql` to publish the 60 original bundled words.
4. Put the project's HTTPS URL and **publishable** key in the Xcode build settings `SUPABASE_PROJECT_URL` and `SUPABASE_PUBLISHABLE_KEY`.
5. Never put a Supabase secret or `service_role` key in the app or GitHub.

The `anon` and `authenticated` roles have read-only access to active, published rows. Row Level Security blocks drafts and all client writes. The app keeps its bundled catalog and a last-known-good cache for offline use.
