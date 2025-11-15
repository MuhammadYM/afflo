# GitHub Actions Workflows

## Overview

Two workflows manage CI/CD:
- **PR Checks**: Validates PRs before merge
- **Deploy Database**: Deploys DB changes to production on merge

## PR Checks (`pr-checks.yml`)

Runs on every PR to `main`. Jobs:
1. **Build** - Compiles iOS app
2. **Lint** - Runs SwiftLint
3. **Validate Migrations** - Checks SQL syntax

## Deploy Database (`deploy-db.yml`)

Triggers on push to `main` when DB files change. Steps:
1. Link to production Supabase project
2. Run `supabase db push --linked`
3. Verify deployment

**Requires manual approval** via GitHub environment protection.

## Setup Required

### 1. Add GitHub Secrets

In repo Settings → Secrets → Actions:
- `SUPABASE_ACCESS_TOKEN`: Generate at https://supabase.com/dashboard/account/tokens
- `SUPABASE_PROJECT_ID`: Project ref from project settings

### 2. Configure Environment Protection

In repo Settings → Environments → Create "production":
- ✅ Required reviewers (add yourself)
- ✅ Wait timer: 0 minutes

### 3. Adding Migrations

```bash
# Create new migration
supabase db diff -f migration_name

# Commit and push
git add supabase/migrations/
git commit -m "Add migration"
git push
```

## Rollback

If deployment fails:
1. Revert the migration commit
2. Push to main
3. Manually fix in Supabase dashboard if needed

## Local Testing

```bash
# Start local Supabase
supabase start

# Apply migrations locally
supabase db reset

# Validate before pushing
supabase db lint
```
