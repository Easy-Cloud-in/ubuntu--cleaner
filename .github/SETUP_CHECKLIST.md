# Setup Checklist for Release Automation

Use this checklist to ensure your release automation is properly configured.

## ☑️ Pre-Setup Checklist

- [ ] Repository is hosted on GitHub
- [ ] You have admin access to the repository
- [ ] Git is configured locally with proper credentials
- [ ] You're familiar with basic git commands

## ☑️ Initial Setup

### 1. Enable GitHub Actions

- [ ] Go to repository Settings
- [ ] Navigate to Actions → General
- [ ] Select "Allow all actions and reusable workflows"
- [ ] Under "Workflow permissions":
  - [ ] Select "Read and write permissions"
  - [ ] Check "Allow GitHub Actions to create and approve pull requests"
- [ ] Click "Save"

### 2. Add Workflow Files

- [ ] Workflow file exists: `.github/workflows/release.yml`
- [ ] Documentation exists: `RELEASE.md`
- [ ] Quick start guide exists: `QUICKSTART.md`
- [ ] README.md updated with release information

### 3. Commit and Push

```bash
# Check current branch
git branch

# Make sure you're on main
git checkout main

# Add all new files
git add .github/workflows/release.yml
git add RELEASE.md
git add QUICKSTART.md
git add README.md

# Commit
git commit -m "feat: add automated release workflow"

# Push to trigger first release
git push origin main
```

- [ ] Files committed
- [ ] Pushed to main branch

## ☑️ Verification

### 4. Check Workflow Execution

- [ ] Go to repository on GitHub
- [ ] Click "Actions" tab
- [ ] See "Create Release" workflow running
- [ ] Workflow completes successfully (green checkmark)

### 5. Verify Release Created

- [ ] Click "Releases" in right sidebar
- [ ] See new release (e.g., v0.0.1 or v2.0.1)
- [ ] Release has a zip file attached
- [ ] Release notes are properly formatted
- [ ] Download link works

### 6. Test the Release Package

```bash
# Download the zip file from releases page
# Then test it:

unzip ubuntu-cleaner-v*.zip
cd ubuntu-cleaner-v*
bash install.sh
./ubuntu-cleaner.sh
```

- [ ] Zip file downloads successfully
- [ ] Zip extracts without errors
- [ ] install.sh runs successfully
- [ ] Script executes properly

## ☑️ Optional Configuration

### 7. Branch Protection (Optional but Recommended)

- [ ] Go to Settings → Branches
- [ ] Add rule for `main` branch
- [ ] Configure protection rules:
  - [ ] Require pull request reviews (optional)
  - [ ] Require status checks to pass (optional)
  - [ ] Allow GitHub Actions to bypass (if using protection)

### 8. Create Initial Version Tag (REQUIRED)

**This step is mandatory!** The workflow will not run without an existing tag.

```bash
# Create initial tag
git tag v2.0.0
git push origin v2.0.0
```

- [ ] Initial version tag created (REQUIRED)
- [ ] Tag pushed to GitHub
- [ ] Tag follows format vMAJOR.MINOR.PATCH (e.g., v1.0.0, v2.0.0)

### 9. Configure Release Settings (Optional)

- [ ] Go to Settings → General
- [ ] Scroll to "Features" section
- [ ] Ensure "Releases" is checked
- [ ] Configure default branch if needed

## ☑️ Testing

### 10. Test Normal Release

```bash
# Make a small change
echo "# Test" >> README.md

# Commit and push
git add README.md
git commit -m "test: verify release automation"
git push origin main
```

- [ ] Workflow triggers automatically
- [ ] New version is created (incremented)
- [ ] Release appears in releases page
- [ ] Zip file is attached

### 11. Test Skip Release

```bash
# Make a change
echo "# Another test" >> README.md

# Commit with skip flag
git add README.md
git commit -m "docs: test skip flag [skip-release]"
git push origin main
```

- [ ] Workflow is skipped
- [ ] No new release created
- [ ] Changes still pushed to main

### 12. Test Manual Version Bump

```bash
# Create a new version tag
git tag v3.0.0
git push origin v3.0.0

# Make a change and push
echo "# Version test" >> README.md
git add README.md
git commit -m "feat: test manual version"
git push origin main
```

- [ ] Release created with manual version
- [ ] Next auto-release will increment from manual version

## ☑️ Troubleshooting

### If Workflow Doesn't Run

- [ ] Check Actions are enabled (Settings → Actions)
- [ ] Verify workflow file is in `.github/workflows/`
- [ ] Confirm you pushed to `main` branch
- [ ] Check commit message doesn't have `[skip-release]`
- [ ] Look at Actions tab for error messages

### If Permissions Error Occurs

- [ ] Settings → Actions → General
- [ ] Workflow permissions → "Read and write permissions"
- [ ] Check "Allow GitHub Actions to create and approve pull requests"
- [ ] Save and re-run workflow

### If Version Doesn't Update in Script

- [ ] Verify script has line: `# Version: X.X`
- [ ] Check sed command in workflow matches format
- [ ] Look at workflow logs for errors

### If Release Not Created

- [ ] Check workflow completed successfully
- [ ] Verify GITHUB_TOKEN has proper permissions
- [ ] Look for errors in "Create GitHub Release" step
- [ ] Check if release already exists with same tag

## ☑️ Documentation

### 13. Update Repository Information

- [ ] Update repository description on GitHub
- [ ] Add topics/tags to repository
- [ ] Update README.md with correct repository URLs
- [ ] Add badges to README (optional)

### 14. Share with Team

- [ ] Share QUICKSTART.md with team members
- [ ] Document any custom modifications
- [ ] Add to team wiki/documentation
- [ ] Train team on release process

## ☑️ Maintenance

### 15. Regular Checks

- [ ] Monitor workflow runs periodically
- [ ] Check release notes are accurate
- [ ] Verify zip files are complete
- [ ] Update documentation as needed

### 16. Version Strategy

- [ ] Decide on version numbering strategy
- [ ] Document when to bump major/minor versions
- [ ] Communicate strategy to team
- [ ] Keep changelog updated

## 📋 Quick Reference

### Common Commands

```bash
# Normal release (auto-increment)
git commit -m "feat: your feature"
git push origin main

# Skip release
git commit -m "docs: update [skip-release]"
git push origin main

# Manual version bump
git tag v3.0.0
git push origin v3.0.0
git push origin main

# Check workflow status
# Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/actions

# View releases
# Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/releases
```

### Workflow Files

- Workflow: `.github/workflows/release.yml`
- Documentation: `RELEASE.md`
- Quick Start: `QUICKSTART.md`
- This Checklist: `.github/SETUP_CHECKLIST.md`
- Diagram: `.github/WORKFLOW_DIAGRAM.md`

## ✅ Setup Complete!

Once all items are checked, your release automation is fully configured and ready to use!

### Next Steps

1. Start developing features
2. Push to main when ready
3. Watch releases get created automatically
4. Share release links with users

### Need Help?

- Check [RELEASE.md](../RELEASE.md) for detailed documentation
- Review [QUICKSTART.md](../QUICKSTART.md) for usage examples
- See [WORKFLOW_DIAGRAM.md](WORKFLOW_DIAGRAM.md) for visual flow
- Check GitHub Actions logs for errors
- Review GitHub Actions documentation

---

**Happy Releasing! 🚀**
