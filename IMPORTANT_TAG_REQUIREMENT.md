# ⚠️ IMPORTANT: Initial Tag Requirement

## What Changed

The release workflow now **requires** an existing version tag before it can run. This prevents potential issues and gives you explicit control over versioning.

## Why This Matters

### Before (Automatic)

- No tags → workflow starts from v0.0.0 → creates v0.0.1
- Could be confusing if you're already at version 2.0

### After (Explicit - Current Implementation)

- No tags → workflow exits with clear error message
- You must create initial tag → workflow increments from there
- Full control over starting version

## What Happens Without a Tag

If you push to main without creating a tag first, the workflow will:

1. ✅ Start running
2. ❌ Check for tags and find none
3. 🛑 Exit with this error message:

```
❌ ERROR: No version tags found in repository!

📋 Before using automated releases, you must create an initial version tag.

To create your first tag, run:
  git tag v1.0.0
  git push origin v1.0.0

Or start from a different version:
  git tag v2.0.0
  git push origin v2.0.0

Then push your changes again to trigger the release workflow.
```

4. ⏹️ Workflow stops (no release created)
5. 📝 You create the tag and push again
6. ✅ Workflow runs successfully

## How to Create Your Initial Tag

### Step 1: Choose Your Starting Version

```bash
# For new projects
git tag v1.0.0

# If you're already at version 2.0
git tag v2.0.0

# Any valid semantic version
git tag vMAJOR.MINOR.PATCH
```

### Step 2: Push the Tag

```bash
git push origin v2.0.0
```

### Step 3: Push Your Changes

```bash
git push origin main
```

Now the workflow will run and create v2.0.1 (incrementing from your v2.0.0 tag).

## Tag Format Validation

The workflow also validates that your tag follows semantic versioning:

### ✅ Valid Tags

- `v1.0.0`
- `v2.5.3`
- `v10.0.1`

### ❌ Invalid Tags

- `1.0.0` (missing 'v' prefix)
- `v1.0` (missing patch version)
- `v1` (missing minor and patch)
- `version-1.0.0` (wrong format)
- `v1.0.0-beta` (pre-release tags not supported yet)

If you have an invalid tag, the workflow will exit with:

```
❌ ERROR: Invalid tag format: version-1.0.0

Tags must follow semantic versioning: vMAJOR.MINOR.PATCH
Examples: v1.0.0, v2.1.3, v10.5.2

Please create a properly formatted tag:
  git tag v1.0.0
  git push origin v1.0.0
```

## Benefits of This Approach

### 1. Explicit Control

You decide the starting version, not the workflow.

### 2. No Surprises

Clear error messages tell you exactly what to do.

### 3. Prevents Mistakes

Can't accidentally start from v0.0.1 when you're at v2.0.

### 4. Better for Teams

Everyone knows the versioning strategy from the start.

### 5. Safer

Workflow won't run until you've made a conscious decision about versioning.

## Quick Reference

### First Time Setup

```bash
# 1. Create initial tag
git tag v2.0.0
git push origin v2.0.0

# 2. Push your changes
git push origin main

# Result: Release v2.0.1 created
```

### Normal Usage (After Initial Tag)

```bash
# Just push to main
git push origin main

# Result: Version auto-increments (v2.0.1 → v2.0.2)
```

### Manual Version Bump

```bash
# Create new tag for major/minor bump
git tag v3.0.0
git push origin v3.0.0

# Push changes
git push origin main

# Result: Release v3.0.0 created, next will be v3.0.1
```

## Troubleshooting

### "No version tags found" Error

**Solution**: Create and push an initial tag:

```bash
git tag v2.0.0
git push origin v2.0.0
git push origin main
```

### "Invalid tag format" Error

**Solution**: Ensure tag follows vMAJOR.MINOR.PATCH format:

```bash
# Wrong
git tag 2.0.0        # Missing 'v'
git tag v2.0         # Missing patch

# Correct
git tag v2.0.0
git push origin v2.0.0
```

### Workflow Runs But No Release

**Check**:

1. Did you create and push a tag first?
2. Is the tag in correct format (vX.Y.Z)?
3. Check Actions tab for error messages

## Summary

✅ **DO**: Create an initial version tag before first push  
✅ **DO**: Use semantic versioning format (vMAJOR.MINOR.PATCH)  
✅ **DO**: Choose your starting version carefully

❌ **DON'T**: Push to main without creating a tag first  
❌ **DON'T**: Use invalid tag formats  
❌ **DON'T**: Expect workflow to auto-create v0.0.1

## Need Help?

- **Quick Start**: See [GET_STARTED.md](GET_STARTED.md)
- **Detailed Guide**: See [RELEASE.md](RELEASE.md)
- **Setup Checklist**: See [.github/SETUP_CHECKLIST.md](.github/SETUP_CHECKLIST.md)

---

**This requirement ensures you have full control over your versioning from day one!**
