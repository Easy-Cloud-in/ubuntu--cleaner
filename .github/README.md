# GitHub Automation Files

This directory contains GitHub Actions workflows and related documentation.

## 📁 Directory Structure

```
.github/
├── workflows/
│   └── release.yml              # Main release automation workflow
├── README.md                    # This file
├── SETUP_CHECKLIST.md          # Step-by-step setup guide
└── WORKFLOW_DIAGRAM.md         # Visual workflow diagrams
```

## 📄 File Descriptions

### workflows/release.yml

The main GitHub Actions workflow that automates the release process.

**Triggers on**: Push to `main` branch  
**Skips if**: Commit message contains `[skip-release]`

**What it does**:

1. Gets the latest version tag
2. Increments the patch version
3. Updates version in ubuntu-cleaner.sh
4. Creates and pushes a new git tag
5. Builds a release package (zip)
6. Creates a GitHub release with the zip file

### SETUP_CHECKLIST.md

A comprehensive checklist for setting up the release automation for the first time.

**Use this when**:

- Setting up the workflow for the first time
- Troubleshooting issues
- Verifying everything is configured correctly

### WORKFLOW_DIAGRAM.md

Visual diagrams showing how the release automation works.

**Includes**:

- Automatic release flow diagram
- Skip release flow
- Manual version control flow
- Version numbering logic
- User download experience
- Decision tree

## 🚀 Quick Links

- **Setup Guide**: [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)
- **Visual Diagrams**: [WORKFLOW_DIAGRAM.md](WORKFLOW_DIAGRAM.md)
- **Main Documentation**: [../RELEASE.md](../RELEASE.md)
- **Quick Start**: [../QUICKSTART.md](../QUICKSTART.md)
- **Implementation Summary**: [../IMPLEMENTATION_SUMMARY.md](../IMPLEMENTATION_SUMMARY.md)

## 🔧 Workflow Configuration

### Key Settings

```yaml
# Trigger
on:
  push:
    branches:
      - main

# Skip condition
if: "!contains(github.event.head_commit.message, '[skip-release]')"
```

### Required Permissions

The workflow needs:

- ✅ Read and write permissions
- ✅ Ability to create releases
- ✅ Ability to push tags
- ✅ Ability to push commits

Configure in: **Settings → Actions → General → Workflow permissions**

## 📝 Customization

### Change Version Increment

Edit `workflows/release.yml` line ~30:

```yaml
# Current: PATCH increment (2.0.0 → 2.0.1)
PATCH=$((PATCH + 1))
NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"

# For MINOR increment (2.0.0 → 2.1.0):
MINOR=$((MINOR + 1))
PATCH=0
NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"
```

### Add Files to Release Package

Edit `workflows/release.yml` line ~60:

```yaml
- name: Create release package
  run: |
    # Add your files here
    cp your-file.txt ubuntu-cleaner-${{ steps.version.outputs.version }}/
```

### Customize Release Notes

Edit `workflows/release.yml` line ~80 in the "Create GitHub Release" step.

## 🐛 Troubleshooting

### Workflow Not Running?

1. Check if Actions are enabled: **Settings → Actions**
2. Verify workflow file exists: `.github/workflows/release.yml`
3. Confirm you pushed to `main` branch
4. Check commit message doesn't have `[skip-release]`

### Permission Errors?

1. Go to **Settings → Actions → General**
2. Under "Workflow permissions":
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"
3. Click "Save"

### Version Not Updating?

1. Check script has format: `# Version: X.X`
2. Review workflow logs for sed command errors
3. Verify file permissions

## 📊 Monitoring

### View Workflow Runs

1. Go to repository on GitHub
2. Click **Actions** tab
3. See all workflow runs with status
4. Click on a run to see detailed logs

### View Releases

1. Go to repository on GitHub
2. Click **Releases** in right sidebar
3. See all published releases
4. Download zip files

## 🎯 Best Practices

1. **Test First**: Test workflow on a test branch before using in production
2. **Monitor Runs**: Check Actions tab regularly for failures
3. **Version Strategy**: Document your version numbering strategy
4. **Skip Wisely**: Use `[skip-release]` for non-functional changes
5. **Manual Bumps**: Use manual tags for major/minor version changes

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Semantic Versioning](https://semver.org/)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)

## ✨ Features

- ✅ Automatic version bumping
- ✅ Git tag creation
- ✅ Release package building
- ✅ GitHub release creation
- ✅ Skip release option
- ✅ Branch protection
- ✅ Error handling
- ✅ Comprehensive logging

## 🎉 Status

**Status**: ✅ Active and Ready  
**Version**: 1.0  
**Last Updated**: October 27, 2025

---

For more information, see the main [RELEASE.md](../RELEASE.md) documentation.
