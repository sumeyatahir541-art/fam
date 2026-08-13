# FAMI Rent Management - Deployment Guide

## Prerequisites

✅ Node.js 18+
✅ Git account
✅ Supabase account
✅ Vercel account

## Step 1: Supabase Setup

### Create Supabase Project
1. Visit https://app.supabase.com
2. Click "New project"
3. Enter project name: `fami-rent`
4. Create strong database password
5. Select region closest to you
6. Click "Create new project"

### Configure Database
1. Go to SQL Editor
2. Click "New Query"
3. Copy-paste content from `scripts/setup-db.sql`
4. Execute query
5. Verify tables created in "Tables" section

### Get API Keys
1. Go to Settings > API
2. Copy **Project URL** (save as VITE_SUPABASE_URL)
3. Copy **Anon Key** under Project API keys (save as VITE_SUPABASE_ANON_KEY)

### Enable Email Verification (Optional but recommended)
1. Go to Authentication > Providers
2. Enable "Email" provider
3. Go to Templates > Confirm signup email
4. Customize message if needed

## Step 2: GitHub Setup

```bash
# Initialize git if not done
git init
git add .
git commit -m "Initial commit: FAMI Rent Management"
git branch -M main
git remote add origin https://github.com/sumeyatahir541-art/fam.git
git push -u origin main
```

## Step 3: Vercel Deployment

### Connect Repository
1. Visit https://vercel.com
2. Click "New Project"
3. Select "Import Git Repository"
4. Find and select `sumeyatahir541-art/fam`
5. Click "Import"

### Configure Project Settings
1. **Framework Preset**: Vite (auto-detected)
2. **Build Command**: `npm run build`
3. **Output Directory**: `dist`
4. **Install Command**: `npm install`

### Add Environment Variables
1. Click "Environment Variables"
2. Add:
   ```
   VITE_SUPABASE_URL = https://your-ref.supabase.co
   VITE_SUPABASE_ANON_KEY = sb_publishable_xxxxxxxx
   ```
3. Select environments: Production, Preview, Development
4. Click "Save"

### Deploy
1. Click "Deploy"
2. Wait for build to complete (~2 minutes)
3. Your app will be at: `https://fam-[random].vercel.app`

## Step 4: Initial Setup

### Create Admin User
1. Open deployed app URL
2. Click "Create account"
3. Sign up with admin email

### Promote to Admin
1. Go to Supabase Dashboard > SQL Editor
2. Execute:
   ```sql
   UPDATE public.profiles
   SET role = 'admin'
   WHERE email = 'admin@email.com';
   ```
3. Refresh app and login
4. Go to "Users" tab (admin-only)
5. Create additional users and assign roles

## Step 5: Custom Domain (Optional)

1. In Vercel project > Settings > Domains
2. Add custom domain
3. Follow DNS configuration steps
4. Wait for verification (typically 1-2 minutes)

## Post-Deployment Checklist

- [ ] Test login/signup functionality
- [ ] Create test shop
- [ ] Record test payment
- [ ] Export report as CSV
- [ ] Test each user role
- [ ] Verify audit logs appear
- [ ] Test on mobile devices
- [ ] Check console for JavaScript errors
- [ ] Enable backup in Supabase (Settings > Backups)
- [ ] Set up alerts for failed transactions

## Troubleshooting

### Build Fails on Vercel
```
ERROR: Could not resolve '@supabase/supabase-js'
```
✅ Solution: Ensure `package.json` has `@supabase/supabase-js` dependency

### "Supabase is not configured" error
✅ Solution: Check environment variables in Vercel are set correctly

### Database not loading
✅ Solution: Verify RLS policies by running test query in Supabase SQL Editor

### Realtime updates not working
✅ Solution: Enable Realtime in Supabase > Project Settings > Realtime

## Monitoring

### Vercel Analytics
- View performance metrics in Vercel Dashboard
- Monitor build times and deployment frequency

### Supabase Monitoring
- Check database performance in Supabase > Monitoring
- Review API usage in Settings > API
- Monitor auth logs in Authentication > Logs

## Backup Strategy

1. **Supabase Backups**:
   - Enable in Settings > Backups
   - Configure daily backups
   - Test restore procedure monthly

2. **GitHub Backups**:
   - Code is automatically backed up via Git
   - Push changes regularly

## Support

- Supabase Docs: https://supabase.com/docs
- Vercel Docs: https://vercel.com/docs
- GitHub Issues: https://github.com/sumeyatahir541-art/fam/issues
