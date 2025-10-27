# Ubuntu Cleaner - Interactive System Cleanup Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/Easy-Cloud-in/ubuntu-cleaner)

An interactive system cleanup script for Ubuntu and Debian-based Linux distributions. Reclaim disk space safely with detailed confirmations and logging.

**Author:** Sakar SR | [easy-cloud.in](https://easy-cloud.in)

## Quick Start

### Option 1: Download and Run (Recommended)

Download the latest release ZIP file, extract it, and run:

```bash
# Download from: https://github.com/Easy-Cloud-in/ubuntu-cleaner/releases
unzip ubuntu-cleaner-vX.X.X.zip
cd ubuntu-cleaner-vX.X.X
./ubuntu-cleaner.sh
```

### Option 2: Clone and Run

```bash
git clone https://github.com/Easy-Cloud-in/ubuntu-cleaner.git
cd ubuntu-cleaner
./ubuntu-cleaner.sh
```

### Option 3: Direct Download

```bash
wget https://raw.githubusercontent.com/Easy-Cloud-in/ubuntu-cleaner/main/ubuntu-cleaner.sh
chmod +x ubuntu-cleaner.sh
./ubuntu-cleaner.sh
```

## What It Does

This tool provides 13 cleanup operations:

1. System Updates
2. APT Package Cleanup
3. System Journal Cleanup
4. User-Level Cleanup (trash, thumbnails)
5. Flatpak & Snap Cleanup
6. AppImage Management
7. Old Kernel Cleanup
8. Docker Cleanup
9. Browser Cache Cleanup
10. User Cache Directory Management
11. System Coredump Cleanup
12. Python Package Cache Cleanup
13. Orphaned Libraries Removal (advanced)

**Features:**

- Real-time disk space tracking
- Color-coded disk usage display
- Interactive confirmations
- Comprehensive logging to `~/.ubuntu-cleaner.log`
- Safety checks and dry-run previews

**Supported Systems:** Ubuntu 24.04 LTS (primary), Ubuntu 22.04, 20.04, and other Debian-based distributions

## Requirements

- Bash shell
- sudo privileges
- Ubuntu or Debian-based Linux distribution

Optional tools (auto-detected): `flatpak`, `snap`, `docker`, `pip3`, `deborphan`

## Usage

Run the script and select from the interactive menu:

```bash
./ubuntu-cleaner.sh
```

**Menu Options:**

- **1-12**: Individual cleanup operations
- **a**: Run all standard cleanups automatically
- **x**: Advanced orphaned library removal
- **l**: View cleanup log
- **c**: Clear log file
- **q**: Quit

## Safety Features

- Confirmation prompts for every operation
- Dry-run previews before removal
- Current kernel protection (keeps current + one previous)
- Critical cache warnings
- Comprehensive logging to `~/.ubuntu-cleaner.log`
- Color-coded disk usage: 🟢 Green (<75%), 🟡 Yellow (75-90%), 🔴 Red (>90%)

## Important Warnings

⚠️ **Browser Cache:** Close all browsers before cleaning caches  
⚠️ **Docker Cleanup:** Removing volumes permanently deletes data - ensure backups  
⚠️ **Old Kernels:** Removed kernels cannot be booted into (current + one previous are kept)  
⚠️ **Critical Caches:** Font/graphics caches will rebuild but may cause temporary slowdowns  
⚠️ **Orphan Removal:** Advanced feature - review carefully before confirming (experienced users only)

## License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2024 Sakar SR

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Support

- Visit: [easy-cloud.in](https://easy-cloud.in)
- Open an issue on [GitHub](https://github.com/Easy-Cloud-in/ubuntu-cleaner)
- Check the log file: `~/.ubuntu-cleaner.log`

## Contributing

Contributions welcome! Submit issues, fork the repository, and create pull requests.

## Disclaimer

**USE AT YOUR OWN RISK.** This script is provided as-is without warranty. Always review operations before confirming and ensure you have backups of important data.

---

**Made with ❤️ by Sakar SR** | [easy-cloud.in](https://easy-cloud.in)

github: [@Easy-Cloud-in]
