# Release Workflow Diagram

## Automatic Release Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     Developer Workflow                          │
└─────────────────────────────────────────────────────────────────┘

    Developer makes changes locally
              ↓
    git add . && git commit -m "feat: new feature"
              ↓
    git push origin main
              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Actions Trigger                       │
│  (Only if: branch = main AND no [skip-release] in commit)      │
└─────────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 1: Get Latest Tag                                         │
│  • Fetch all git tags                                           │
│  • Find latest version (e.g., v2.0.0)                          │
│  • If no tags exist, use v0.0.0                                │
└─────────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 2: Increment Version                                      │
│  • Parse version: v2.0.0 → MAJOR=2, MINOR=0, PATCH=0          │
│  • Increment PATCH: PATCH = 0 + 1 = 1                         │
│  • New version: v2.0.1                                         │
└─────────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 3: Update Script Version                                  │
│  • Find line: "# Version: 2.0"                                 │
│  • Replace with: "# Version: 2.0.1"                            │
│  • Commit change to repository                                  │
└─────────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 4: Create and Push Tag                                    │
│  • Create git tag: v2.0.1                                      │
│  • Push tag to origin                                           │
└─────────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 5: Build Release Package                                  │
│  • Create directory: ubuntu-cleaner-v2.0.1/                    │
│  • Copy files:                                                  │
│    - ubuntu-cleaner.sh                                          │
│    - README.md                                                  │
│    - LICENSE (if exists)                                        │
│  • Generate install.sh script                                   │
│  • Create zip: ubuntu-cleaner-v2.0.1.zip                       │
└─────────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 6: Create GitHub Release                                  │
│  • Tag: v2.0.1                                                 │
│  • Title: "Ubuntu Cleaner v2.0.1"                              │
│  • Body: Installation instructions + changelog                  │
│  • Attach: ubuntu-cleaner-v2.0.1.zip                           │
│  • Publish release                                              │
└─────────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Release Published! 🎉                        │
│  Users can now download the zip file from Releases page        │
└─────────────────────────────────────────────────────────────────┘
```

## Skip Release Flow

```
    Developer makes changes locally
              ↓
    git commit -m "docs: update README [skip-release]"
              ↓
    git push origin main
              ↓
┌─────────────────────────────────────────────────────────────────┐
│              GitHub Actions Check                               │
│  Detects [skip-release] in commit message                      │
│  → Workflow skipped, no release created                        │
└─────────────────────────────────────────────────────────────────┘
              ↓
    Changes pushed to main, no release
```

## Manual Version Control Flow

```
    Developer wants to bump major/minor version
              ↓
    git tag v3.0.0
              ↓
    git push origin v3.0.0
              ↓
    git push origin main
              ↓
┌─────────────────────────────────────────────────────────────────┐
│              GitHub Actions Workflow                            │
│  • Detects latest tag: v3.0.0                                  │
│  • Next auto-release will be: v3.0.1                           │
│  • Creates release for v3.0.0                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Version Numbering Logic

```
Semantic Versioning: vMAJOR.MINOR.PATCH

┌──────────────────────────────────────────────────────────────┐
│  MAJOR (v3.0.0)                                              │
│  • Breaking changes                                           │
│  • Incompatible API changes                                   │
│  • Manual bump recommended                                    │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  MINOR (v2.1.0)                                              │
│  • New features                                               │
│  • Backward compatible                                        │
│  • Manual bump recommended                                    │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  PATCH (v2.0.1)                                              │
│  • Bug fixes                                                  │
│  • Small improvements                                         │
│  • Auto-bumped by workflow                                    │
└──────────────────────────────────────────────────────────────┘

Examples:
  v2.0.0 → v2.0.1 (auto: bug fix)
  v2.0.1 → v2.0.2 (auto: another fix)
  v2.0.2 → v2.1.0 (manual: new feature)
  v2.1.0 → v3.0.0 (manual: breaking change)
```

## User Download Experience

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Repository                            │
│                                                                 │
│  [Code] [Issues] [Pull requests] [Actions] [Releases] ←        │
└─────────────────────────────────────────────────────────────────┘
                                                    ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Releases Page                              │
│                                                                 │
│  📦 Ubuntu Cleaner v2.0.1                                      │
│     Latest • 2 hours ago                                        │
│                                                                 │
│     Installation instructions...                                │
│                                                                 │
│     Assets:                                                     │
│     📁 ubuntu-cleaner-v2.0.1.zip (125 KB) ← Download           │
└─────────────────────────────────────────────────────────────────┘
                    ↓
        User downloads zip file
                    ↓
┌─────────────────────────────────────────────────────────────────┐
│              User's Computer                                    │
│                                                                 │
│  $ unzip ubuntu-cleaner-v2.0.1.zip                             │
│  $ cd ubuntu-cleaner-v2.0.1                                    │
│  $ bash install.sh                                              │
│  $ ./ubuntu-cleaner.sh                                          │
│                                                                 │
│  ✅ Script running!                                            │
└─────────────────────────────────────────────────────────────────┘
```

## Workflow Decision Tree

```
                    Push to GitHub
                          ↓
                    ┌─────────┐
                    │ Branch? │
                    └─────────┘
                    ↙         ↘
              main              other
                ↓                 ↓
        ┌──────────────┐      [Skip workflow]
        │ Commit msg?  │
        └──────────────┘
        ↙              ↘
[skip-release]    normal commit
      ↓                 ↓
[Skip workflow]   ┌──────────────┐
                  │ Run workflow │
                  └──────────────┘
                        ↓
                  ┌──────────────┐
                  │ Get tags     │
                  └──────────────┘
                        ↓
                  ┌──────────────┐
                  │ Increment    │
                  │ version      │
                  └──────────────┘
                        ↓
                  ┌──────────────┐
                  │ Update       │
                  │ script       │
                  └──────────────┘
                        ↓
                  ┌──────────────┐
                  │ Create tag   │
                  └──────────────┘
                        ↓
                  ┌──────────────┐
                  │ Build zip    │
                  └──────────────┘
                        ↓
                  ┌──────────────┐
                  │ Create       │
                  │ release      │
                  └──────────────┘
                        ↓
                    Success! 🎉
```

## Key Features

### ✅ Automatic

- No manual intervention needed
- Runs on every push to main
- Handles version incrementing

### ✅ Safe

- Only runs from main branch
- Can be skipped with flag
- Keeps git history clean

### ✅ User-Friendly

- Single zip download
- Includes installation script
- Clear documentation

### ✅ Flexible

- Skip releases when needed
- Manual version control option
- Customizable workflow

### ✅ Professional

- Semantic versioning
- Proper release notes
- Changelog links
