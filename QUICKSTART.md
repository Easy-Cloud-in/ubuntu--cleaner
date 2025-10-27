# Quick Start Guide for Release Automation

## 🚀 Getting Started

Your repository is now set up with automatic release creation! Here's what you need to know:

## ✅ What's Already Done

1. ✅ GitHub Actions workflow created (`.github/workflows/release.yml`)
2. ✅ Automatic version bumping configured
3. ✅ Release packaging set up
4. ✅ Documentation created

## 🎯 Next Steps

### 1. Enable GitHub Actions (if not already enabled)

1. Go to your repository on GitHub
2. Click on "Settings" tab
3. Click "Actions" → "General" in the left sidebar
4. Under "Actions permissions", select "Allow all actions and reusable workflows"
5. Under "Workflow permissions", select "Read and write permissions"
6. Check "Allow GitHub Actions to create and approve pull requests"
7. Click "Save"

### 2. Create Initial Version Tag (REQUIRED)

Before the workflow can run, you MUST create an initial version tag:

```bash
# Create your starting version
git tag v2.0.0

# Push the tag to GitHub
git push origin v2.0.0
```

**Why?** The workflow requires an existing tag to know where to start versioning.

### 3. Push Your Changes

```bash
# Make sure you're on main branch
git checkout main

# Add the new workflow files
git add .github/workflows/release.yml RELEASE.md QUICKSTART.md README.md
git commit -m "feat: add automated release workflow"

# Push to trigger the first release
git push origin main
```

This will create version `v2.0.1` (incrementing from your v2.0.0 tag).

### 4. Verify the Release

1. Go to your repository on GitHub
2. Click on "Actions" tab to see the workflow running
3. Once complete, click "Releases" in the right sidebar
4. You should see your new release with the zip file!

## 📝 Daily Usage

### Creating a New Release

Just push to main:

```bash
git add .
git commit -m "feat: your changes here"
git push origin main
```

**That's it!** The workflow will:

- Auto-increment the version (e.g., v2.0.1 → v2.0.2)
- Update the version in the script
- Create a git tag
- Build a zip package
- Create a GitHub release

### Skipping a Release

Add `[skip-release]` to your commit message:

```bash
git commit -m "docs: update README [skip-release]"
git push origin main
```

Use this for:

- Documentation updates
- Minor fixes
- Work in progress

### Manual Version Control

For major or minor version bumps:

```bash
# Create the tag first
git tag v3.0.0
git push origin v3.0.0

# Then push your changes
git push origin main
```

## 🎨 Customization Options

### Change Version Increment Logic

Edit `.github/workflows/release.yml` and modify the version increment section:

```yaml
# Current: Increments PATCH (2.0.0 → 2.0.1)
PATCH=$((PATCH + 1))
NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"

# For MINOR increment (2.0.0 → 2.1.0):
MINOR=$((MINOR + 1))
PATCH=0
NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"
```

### Add More Files to Release

Edit the "Create release package" step:

```yaml
- name: Create release package
  run: |
    # Add more files here
    cp your-file.txt ubuntu-cleaner-${{ steps.version.outputs.version }}/
```

### Customize Release Notes

Edit the "Create GitHub Release" step to change the body content.

## 🔧 Troubleshooting

### Workflow Not Running?

**Check:**

1. GitHub Actions is enabled (Settings → Actions)
2. Workflow file is in `.github/workflows/` directory
3. You pushed to `main` branch (not another branch)
4. Commit message doesn't contain `[skip-release]`

### Permission Errors?

**Fix:**

1. Settings → Actions → General
2. Workflow permissions → "Read and write permissions"
3. Check "Allow GitHub Actions to create and approve pull requests"

### Branch Protection Issues?

If you have branch protection on `main`:

1. Settings → Branches → Branch protection rules
2. Enable "Allow GitHub Actions to bypass branch protection"

### Version Not Updating in Script?

Check that the script has this line format:

```bash
# Version: 2.0
```

The workflow looks for `# Version:` to update it.

## 📚 More Information

- **Full Documentation**: See [RELEASE.md](RELEASE.md)
- **Workflow File**: `.github/workflows/release.yml`
- **GitHub Actions Docs**: https://docs.github.com/en/actions

## 💡 Tips

1. **Initial Tag Required**: You MUST create a version tag before the workflow can run
2. **Starting Version**: Choose your starting version (v1.0.0, v2.0.0, etc.) when creating the initial tag
3. **Testing**: Test the workflow on a separate branch first if you want
4. **Monitoring**: Watch the Actions tab to see workflow progress
5. **Rollback**: If something goes wrong, delete the tag and release, then fix and re-push

## ✨ Benefits

- ✅ No manual release creation
- ✅ Consistent version numbering
- ✅ Professional release packages
- ✅ Automatic changelog links
- ✅ Easy for users to download and use
- ✅ Full git history tracking

## 🎉 You're All Set!

Your release automation is ready to go. Just push to main and watch the magic happen!

Questions? Check [RELEASE.md](RELEASE.md) for detailed documentation.
