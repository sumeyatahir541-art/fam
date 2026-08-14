# Deployment notes: deploying without a live Supabase database

This repository uses Supabase for runtime data. If you need to deploy the site to Vercel but the database or environment variables are not yet available or you want to temporarily avoid runtime DB connections, you can enable a safe feature flag that disables DB calls and falls back to a noop client.

Steps to deploy without a DB (temporary)

1. In your Vercel project, go to Settings → Environment Variables.
2. Add a new variable:
   - Key: VITE_DISABLE_DB
   - Value: true
   - Environment: Production (and Preview if you want)
3. (Optional) You can leave VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY empty while the flag is set.
4. Redeploy the project. The UI will render but runtime data will be empty (no database calls).

When ready to re-enable the real DB:

1. Remove or set VITE_DISABLE_DB to false.
2. Add correct values for VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in Vercel.
3. Redeploy.

Notes
- This is a temporary mitigation to allow the site to deploy without crashing. It returns empty datasets and no-op realtime subscriptions.
- For production, ensure proper Supabase credentials and network access are configured.
