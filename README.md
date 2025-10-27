# Ubuntu Cleaner - Interactive System Cleanup Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/Easy-Cloud-in/ubuntu-cleaner)

An interactive, comprehensive system cleanup script for Ubuntu and Debian-based Linux distributions. This tool helps you reclaim disk space safely with detailed confirmations and logging.

## Author

**Sakar SR**  
Website: [easy-cloud.in](https://easy-cloud.in)

## Features

### Standard Cleanup Operations (12 Functions)

1. **System Updates** - Update package lists and upgrade all installed packages with reboot detection
2. **APT Package Cleanup** - Remove unused packages, clean package cache, and purge residual configuration files
3. **System Journal Cleanup** - Manage systemd journal logs by time or size limits
4. **User-Level Cleanup** - Empty trash and remove thumbnail caches
5. **Flatpak & Snap Cleanup** - Remove unused Flatpak runtimes and old Snap revisions
6. **AppImage Management** - Interactive removal of AppImage files with size analysis
7. **Old Kernel Cleanup** - Safely remove old kernel versions while keeping current and one previous
8. **Docker Cleanup** - Comprehensive Docker cleanup (containers, images, volumes, system-wide prune)
9. **Browser Cache Cleanup** - Clean caches for Firefox, Chrome, Chromium, and Brave browsers
10. **User Cache Directory Management** - Manage ~/.cache subdirectories with warnings for critical caches
11. **System Coredump Cleanup** - Remove crash dump files from failed applications
12. **Python Package Cache Cleanup** - Purge pip/pip3 cache to free up space

### Advanced Operations (1 Function)

13. **Orphaned Libraries Removal** - Find and remove orphaned libraries using deborphan (use with caution)

### Additional Features

- **Real-time disk space tracking** - See how much space each operation frees
- **Color-coded disk usage display** - Visual indicators for disk usage levels (green/yellow/red)
- **Comprehensive logging** - All operations logged to `~/.ubuntu-cleaner.log`
- **Interactive confirmations** - Review changes before applying them
- **Safety checks** - Warnings for critical operations and version verification
- **Dry-run previews** - See what will be removed before confirming
- **Error handling** - Graceful error handling with informative messages

## Supported Operating Systems

- **Primary**: Ubuntu 24.04 LTS
- **Compatible**: Ubuntu 22.04, 20.04, and other Debian-based distributions

The script will warn you if running on a version other than Ubuntu 24.04 but allows you to proceed.

## Requirements

- Bash shell
- sudo privileges
- Ubuntu or Debian-based Linux distribution

### Optional Dependencies

The script will automatically detect and work with these tools if installed:

- `flatpak` - For Flatpak cleanup
- `snap` - For Snap cleanup
- `docker` - For Docker cleanup
- `pip3` - For Python package cache cleanup
- `deborphan` - For orphaned library detection (automatically installed when you select the advanced cleanup option)

**Note about deborphan**: When you select the advanced orphaned libraries removal option (Step x), the script will automatically check if `deborphan` is installed. If not found, it will prompt you and install it automatically using:

```bash
sudo apt install deborphan -y
```

You can also install it manually beforehand:

```bash
sudo apt install deborphan
```

## Installation

### Option 1: Download Release (Recommended)

1. Go to the [Releases](https://github.com/yourusername/ubuntu-cleaner/releases) page
2. Download the latest `ubuntu-cleaner-vX.X.X.zip`
3. Extract and install:

```bash
unzip ubuntu-cleaner-vX.X.X.zip
cd ubuntu-cleaner-vX.X.X
bash install.sh
./ubuntu-cleaner.sh
```

### Option 2: Direct Download

1. Download the script:

```bash
wget https://raw.githubusercontent.com/yourusername/ubuntu-cleaner/main/ubuntu-cleaner.sh
```

2. Make it executable:

```bash
chmod +x ubuntu-cleaner.sh
```

3. Run the script:

```bash
./ubuntu-cleaner.sh
```

## Usage

### Interactive Menu

Run the script and select operations from the interactive menu:

```bash
./ubuntu-cleaner.sh
```

The menu displays:

- Current disk usage with color-coded indicators
- Numbered cleanup options
- Utility functions (view/clear logs)
- Advanced operations
- Quick "Run All" option

### Menu Options

- **1-12**: Individual cleanup operations
- **l**: View cleanup log
- **c**: Clear log file
- **x**: Advanced orphaned library removal
- **a**: Run all standard cleanup steps automatically
- **q**: Quit the script

### Example Workflow

1. Run the script: `./ubuntu-cleaner.sh`
2. Review disk usage at the top of the menu
3. Select option `a` to run all standard cleanups
4. Review and confirm each operation
5. Check the log with option `l` to see what was cleaned

## Safety Features

- **Confirmation prompts** - Every destructive operation requires user confirmation
- **Dry-run previews** - See what will be removed before confirming
- **Current kernel protection** - Always keeps current and one previous kernel
- **Critical cache warnings** - Alerts for font, graphics, and system caches
- **Size calculations** - Shows how much space will be freed
- **Comprehensive logging** - All actions logged with timestamps
- **Error handling** - Graceful failures with informative messages

## Log File

All operations are logged to: `~/.ubuntu-cleaner.log`

View the log:

- From the menu: Select option `l`
- Manually: `less ~/.ubuntu-cleaner.log`

Clear the log:

- From the menu: Select option `c`
- Manually: `rm ~/.ubuntu-cleaner.log`

## Disk Space Indicators

The menu displays color-coded disk usage:

- 🟢 **Green**: < 75% used (healthy)
- 🟡 **Yellow**: 75-90% used (monitor)
- 🔴 **Red**: > 90% used (critical)

## Important Warnings

### ⚠️ Browser Cache Cleanup

Close all browsers before cleaning their caches to avoid data corruption.

### ⚠️ Docker Cleanup

Removing Docker volumes permanently deletes data. Ensure you have backups.

### ⚠️ Old Kernel Cleanup

The script keeps your current kernel and one previous version for safety. Removed kernels cannot be booted into.

### ⚠️ Critical Cache Directories

Some caches (fontconfig, mesa_shader_cache, nvidia) are critical for system performance. They will be rebuilt automatically but may cause temporary slowdowns.

### ⚠️ Advanced Orphan Removal (deborphan)

**For experienced users only!** This feature uses `deborphan` to find and remove orphaned libraries that appear to have no dependencies. However:

- Misidentification can break software dependencies
- Some packages may be incorrectly flagged as orphaned
- Always review the list carefully before confirming removal
- The script will automatically install `deborphan` if not present

**What happens when you select this option:**

1. Script checks if `deborphan` is installed
2. If not found, it automatically installs it with your permission
3. Scans for orphaned packages
4. Shows you the list for review
5. Requires explicit confirmation before removal

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

## Disclaimer

**USE AT YOUR OWN RISK**

This script is provided as-is without any warranty. While it includes safety checks and confirmations, the author is not responsible for any data loss or system issues that may occur. Always:

- Review what will be removed before confirming
- Ensure you have backups of important data
- Test on a non-production system first
- Read the warnings and understand the operations

## Release Automation

This project uses automated releases via GitHub Actions. When you push to `main`, a new version is automatically created and released.

**For maintainers:** See [RELEASE.md](RELEASE.md) for detailed information about:

- How automatic versioning works
- How to skip releases with `[skip-release]` flag
- How to manually control version numbers
- Troubleshooting and best practices

## Contributing

Contributions are welcome! Please feel free to submit issues, fork the repository, and create pull requests.

## Support

For issues, questions, or suggestions:

- Visit: [easy-cloud.in](https://easy-cloud.in)
- Open an issue on GitHub
- Review the log file for troubleshooting

## Changelog

### Version 2.0

- Added 12 standard cleanup operations + 1 advanced operation (13 total)
- Implemented real-time space tracking
- Added color-coded disk usage indicators
- Enhanced safety checks and confirmations
- Comprehensive logging system
- Interactive AppImage management
- Docker cleanup support
- Browser cache cleanup for multiple browsers
- User cache directory management
- Coredump and pip cache cleanup
- Advanced orphaned library removal
- "Run All" automation option

### Version 1.2

- Initial release with basic cleanup functions

## Acknowledgments

Built for the Ubuntu community to help maintain clean and efficient systems.

---

**Made with ❤️ by Sakar SR** | [easy-cloud.in](https://easy-cloud.in)
