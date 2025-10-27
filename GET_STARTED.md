# 🚀 Get Started with Release Automation

Welcome! Your release automation is ready to use. This guide will get you up and running in 5 minutes.

## ⚡ Quick Start (6 Minutes)

### Step 1: Enable GitHub Actions (2 minutes)

1. Go to your repository on GitHub
2. Click **Settings** → **Actions** → **General**
3. Select "Allow all actions and reusable workflows"
4. Under "Workflow permissions":
   - ✅ Select "Read and write permissions"
   - ✅ Check "Allow GitHub Actions to create and approve pull requests"
5. Click **Save**

### Step 2: Create Initial Version Tag (1 minute)

Before the workflow can run, you need to create an initial version tag:

```bash
# Create your first version tag
git tag v2.0.0

# Push the tag
git push origin v2.0.0
```

**Note**: Choose your starting version (v1.0.0, v2.0.0, etc.). The workflow will auto-increment from there.

### Step 3: Push the Files (1 minute)

```bash
# Make sure you're on main branch
git checkout main

# Add all the new files
git add .

# Commit
git commit -m "feat: add automated release workflow"

# Push to trigger your first release!
git push origin main
```

### Step 4: Watch the Magic (2 minutes)

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. Watch the "Create Release" workflow run
4. Once complete (green checkmark), click **Releases** in the right sidebar
5. See your new release with the zip file! 🎉

## ✅ That's It!

Your release automation is now active. Every time you push to `main`, a new release will be created automatically.

## 📖 What to Read Next

### For Immediate Use

→ **[QUICKSTART.md](QUICKSTART.md)** - Quick reference guide

### For Detailed Information

→ **[RELEASE.md](RELEASE.md)** - Comprehensive documentation

### For Setup Verification

→ **[.github/SETUP_CHECKLIST.md](.github/SETUP_CHECKLIST.md)** - Verify everything works

### For Visual Understanding

→ **[.github/WORKFLOW_DIAGRAM.md](.github/WORKFLOW_DIAGRAM.md)** - See how it works

### For Complete Overview

→ **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Full implementation details

## 🎯 Common Tasks

### Create a Normal Release

```bash
# Make your changes
vim ubuntu-cleaner.sh

# Commit and push
git add .
git commit -m "feat: add new feature"
git push origin main

# ✅ Release created automatically!
```

### Skip a Release

```bash
# For documentation updates or minor changes
git commit -m "docs: update README [skip-release]"
git push origin main

# ✅ No release created, just pushed to main
```

### Manual Version Bump

```bash
# For major or minor version changes
git tag v3.0.0
git push origin v3.0.0
git push origin main

# ✅ Release v3.0.0 created
```

## 📦 What Gets Released

Each release includes a zip file with:

- ✅ `ubuntu-cleaner.sh` - Your main script
- ✅ `README.md` - Documentation
- ✅ `LICENSE` - License file
- ✅ `install.sh` - Installation script (auto-generated)

Users just download, extract, and run!

## 🎨 How It Works

```
You push to main
    ↓
GitHub Actions runs
    ↓
Version auto-increments (v2.0.0 → v2.0.1)
    ↓
Script version updated
    ↓
Git tag created
    ↓
Zip package built
    ↓
Release published
    ↓
Users can download! 🎉
```

## 🔧 Troubleshooting

### Workflow Not Running?

**Quick Fix:**

1. Check Actions are enabled (Settings → Actions)
2. Verify you pushed to `main` branch
3. Ensure commit doesn't have `[skip-release]`

### Permission Error?

**Quick Fix:**

1. Settings → Actions → General
2. Workflow permissions → "Read and write permissions"
3. Check "Allow GitHub Actions to create and approve pull requests"
4. Save and retry

### Need More Help?

- Check [QUICKSTART.md](QUICKSTART.md) for common issues
- Review [.github/SETUP_CHECKLIST.md](.github/SETUP_CHECKLIST.md) for setup verification
- See workflow logs in Actions tab

## 💡 Pro Tips

1. **Initial Tag Required**: You MUST create a version tag (e.g., v2.0.0) before the workflow can run
2. **Choose Wisely**: Pick your starting version carefully - the workflow will auto-increment from there
3. **Skip Docs**: Use `[skip-release]` for documentation-only changes
4. **Monitor**: Watch the Actions tab to see workflow progress
5. **Test**: Everything is safe to test - you can delete releases and try again

## 🎉 Benefits

### For You (Maintainer)

- ⚡ No manual release creation
- 🎯 Consistent version numbering
- 📝 Automatic changelog links
- ⏰ Time saved on every release

### For Users

- 📦 Easy to find releases
- ⬇️ Single zip download
- 🚀 Simple installation
- 📊 Clear version numbers

## 📚 Documentation Structure

```
📁 Your Repository
├── 📄 GET_STARTED.md          ← You are here! (Start here)
├── 📄 QUICKSTART.md            ← Quick reference guide
├── 📄 RELEASE.md               ← Comprehensive documentation
├── 📄 IMPLEMENTATION_SUMMARY.md ← Complete overview
├── 📄 LICENSE                  ← MIT License
├── 📄 README.md                ← Project README
├── 📄 ubuntu-cleaner.sh        ← Your script
└── 📁 .github/
    ├── 📁 workflows/
    │   └── 📄 release.yml      ← Main workflow
    ├── 📄 README.md            ← GitHub automation docs
    ├── 📄 SETUP_CHECKLIST.md   ← Setup verification
    └── 📄 WORKFLOW_DIAGRAM.md  ← Visual diagrams
```

## 🎯 Next Steps

1. ✅ **Enable GitHub Actions** (if not done)
2. ✅ **Create initial version tag** (e.g., v2.0.0)
3. ✅ **Push the files** to trigger first release
4. ✅ **Verify release** is created
5. ✅ **Test download** the zip file
6. ✅ **Start using** it for real!

## 🌟 You're All Set!

Your release automation is ready to go. Just push to main and watch releases get created automatically!

### Questions?

- **Quick answers**: [QUICKSTART.md](QUICKSTART.md)
- **Detailed info**: [RELEASE.md](RELEASE.md)
- **Setup help**: [.github/SETUP_CHECKLIST.md](.github/SETUP_CHECKLIST.md)
- **Visual guide**: [.github/WORKFLOW_DIAGRAM.md](.github/WORKFLOW_DIAGRAM.md)

---

**Happy Releasing! 🚀**

Made with ❤️ for easy, automated releases
