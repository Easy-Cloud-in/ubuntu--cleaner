# Release Automation Guide

This repository uses GitHub Actions to automatically create releases when you push to the `main` branch.

## How It Works

### Automatic Version Bumping

1. **Push to main** - When you push commits to the `main` branch from your local `main` branch
2. **Version Detection** - The workflow finds the latest git tag (e.g., `v2.0.0`)
3. **Auto-Increment** - Automatically increments the patch version (e.g., `v2.0.0` → `v2.0.1`)
4. **Update Script** - Updates the version number in `ubuntu-cleaner.sh`
5. **Create Tag** - Creates and pushes the new version tag
6. **Build Release** - Creates a zip package with all necessary files
7. **Publish** - Creates a GitHub release with the zip file attached

### What Gets Packaged

The release zip file includes:

- `ubuntu-cleaner.sh` - The main cleanup script
- `README.md` - Complete documentation
- `LICENSE` - License file (if present)
- `install.sh` - Quick installation script for users

## Usage

### Normal Release (Auto-versioning)

Simply push your changes to main:

```bash
git add .
git commit -m "feat: add new cleanup feature"
git push origin main
```

This will automatically:

- Bump the version from `v2.0.0` to `v2.0.1`
- Create a release with the zip file
- Update the version in the script

### Skip Release

If you want to push changes without creating a release, add `[skip-release]` to your commit message:

```bash
git commit -m "docs: update README [skip-release]"
git push origin main
```

This is useful for:

- Documentation updates
- Minor fixes that don't need a new release
- Work-in-progress commits

### Manual Version Control

If you want to control the version manually, you can create a tag before pushing:

```bash
# Create a specific version tag
git tag v3.0.0
git push origin main
git push origin v3.0.0
```

The workflow will detect this tag and use it as the base for the next auto-increment.

## Version Numbering

The workflow uses semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR** - Breaking changes (manual bump recommended)
- **MINOR** - New features (manual bump recommended)
- **PATCH** - Bug fixes and small improvements (auto-bumped)

### Manually Bumping Major/Minor Versions

For major or minor version bumps, create the tag manually:

```bash
# For a minor version bump (new feature)
git tag v2.1.0
git push origin v2.1.0

# For a major version bump (breaking change)
git tag v3.0.0
git push origin v3.0.0
```

Then push your changes:

```bash
git push origin main
```

The next auto-release will increment from your manual tag (e.g., `v3.0.0` → `v3.0.1`).

## First Release

**IMPORTANT**: The workflow requires an existing version tag to function. If no tags exist, the workflow will exit with an error message.

### Creating Your Initial Tag

Before your first release, you MUST create an initial version tag:

```bash
# Create your starting version tag
git tag v2.0.0

# Push the tag to GitHub
git push origin v2.0.0
```

Then push your changes to trigger the workflow:

```bash
git push origin main
```

### Choosing Your Starting Version

- `v1.0.0` - For new projects starting fresh
- `v2.0.0` - If your project is already at version 2.0
- Any valid semantic version following the format `vMAJOR.MINOR.PATCH`

The workflow will auto-increment from whatever tag you create (e.g., `v2.0.0` → `v2.0.1`).

## Workflow Requirements

### GitHub Permissions

The workflow needs write permissions to:

- Create tags
- Create releases
- Push commits (for version updates)

These are automatically granted via `GITHUB_TOKEN`.

### Branch Protection

If you have branch protection rules on `main`:

1. Go to Settings → Branches → Branch protection rules
2. Enable "Allow GitHub Actions to bypass branch protection"
3. Or add the GitHub Actions bot to the bypass list

## Troubleshooting

### Release Not Created

**Check if:**

- Commit message contains `[skip-release]`
- You pushed to a branch other than `main`
- GitHub Actions is enabled in your repository
- Workflow file is in `.github/workflows/` directory

### Version Not Incrementing

**Check if:**

- Tags are being created properly (`git tag -l`)
- Previous releases have proper version tags
- Workflow has permission to push tags

### Permission Errors

**Fix by:**

1. Go to Settings → Actions → General
2. Under "Workflow permissions"
3. Select "Read and write permissions"
4. Check "Allow GitHub Actions to create and approve pull requests"

## Examples

### Example 1: Regular Feature Release

```bash
# Make changes
vim ubuntu-cleaner.sh

# Commit and push
git add ubuntu-cleaner.sh
git commit -m "feat: add browser cache cleanup"
git push origin main

# Result: v2.0.0 → v2.0.1 release created automatically
```

### Example 2: Documentation Update (No Release)

```bash
# Update docs
vim README.md

# Commit with skip flag
git add README.md
git commit -m "docs: improve installation instructions [skip-release]"
git push origin main

# Result: No release created, just pushed to main
```

### Example 3: Major Version Release

```bash
# Make breaking changes
vim ubuntu-cleaner.sh

# Commit changes
git add ubuntu-cleaner.sh
git commit -m "feat!: redesign menu system (breaking change)"

# Create major version tag
git tag v3.0.0
git push origin v3.0.0

# Push changes
git push origin main

# Result: v3.0.0 release created, next auto-release will be v3.0.1
```

## User Download Experience

Users will see releases on your GitHub repository's releases page:

1. Click on "Releases" in the right sidebar
2. Download `ubuntu-cleaner-vX.X.X.zip`
3. Extract and run:
   ```bash
   unzip ubuntu-cleaner-v2.0.1.zip
   cd ubuntu-cleaner-v2.0.1
   bash install.sh
   ./ubuntu-cleaner.sh
   ```

Simple and straightforward!

## Benefits

✅ **Automated** - No manual release creation needed  
✅ **Consistent** - Version numbers always increment properly  
✅ **User-Friendly** - Single zip file with everything included  
✅ **Flexible** - Skip releases when needed with a flag  
✅ **Traceable** - All releases tagged in git history  
✅ **Professional** - Clean release notes and changelog links

## Questions?

- Check the workflow runs: Actions tab in GitHub
- View workflow file: `.github/workflows/release.yml`
- See all releases: Releases section in GitHub
