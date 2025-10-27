#!/bin/bash

# ==============================================================================
# Interactive Ubuntu Cleanup Script - Enhanced Version
# Version: 2.0.2
# For Ubuntu 24.04 LTS and similar Debian-based systems.
#
# DISCLAIMER: This script is provided as-is. Always review the actions
# before confirming. The author is not responsible for data loss.
# Improvements: Added safety checks, error handling, input validation,
# space tracking, activity logging, and enhanced cleanup capabilities.
# ==============================================================================

# --- Color codes for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Configuration file support ---
# Check for config file in script directory first, then fall back to home directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.ubuntu-cleaner.conf"

# If config file exists in script directory, use it instead
if [ -f "$SCRIPT_DIR/ubuntu-cleaner.conf" ]; then
    CONFIG_FILE="$SCRIPT_DIR/ubuntu-cleaner.conf"
fi

# Default configuration
DEFAULT_CONFIG="# Ubuntu Cleaner Configuration
# Log file location
LOG_FILE=~/.ubuntu-cleaner.log

# Space tracking threshold (GB)
SPACE_TRACKING_THRESHOLD=1

# Keep minimum kernels
MINIMUM_KERNELS=2

# Browser cache warning size (MB)
BROWSER_CACHE_WARNING_SIZE=1024

# Enable/disable features
ENABLE_DOCKER_CLEANUP=true
ENABLE_FLATPAK_CLEANUP=true
ENABLE_SNAP_CLEANUP=true
ENABLE_APPIMAGE_CLEANUP=true
ENABLE_ORPHAN_CLEANUP=false

# Custom cleanup paths
CUSTOM_CACHE_PATHS=()
"

# Load configuration if it exists
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Source configuration file
        source "$CONFIG_FILE"
        echo -e "${GREEN}Loaded configuration from: $CONFIG_FILE${NC}"
    else
        echo -e "${BLUE}No configuration file found. Using built-in defaults.${NC}"
        echo -e "${BLUE}Default config locations: ${SCRIPT_DIR}/ubuntu-cleaner.conf or $CONFIG_FILE${NC}"
        echo -e "${BLUE}Copy ${SCRIPT_DIR}/ubuntu-cleaner.conf to your home directory to customize settings.${NC}"
    fi
}

# Load configuration at startup
load_config

# --- Log file location ---
LOG_FILE=~/.ubuntu-cleaner.log

# --- Helper function to print a separator ---
print_separator() {
    echo -e "${BLUE}------------------------------------------------------------${NC}"
}

# --- Function to log actions ---
log_action() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

# --- Function to get available disk space in GB ---
get_available_space() {
    df -BG / | awk 'NR==2 {print $4}' | sed 's/G//'
}

# --- Function to show space saved ---
show_space_saved() {
    local before=$1
    local after=$2
    local saved=$((after - before))
    if [ $saved -gt 0 ]; then
        echo -e "${GREEN}✓ Space freed: ${saved}GB${NC}"
        log_action "Space freed: ${saved}GB"
    else
        echo -e "${BLUE}No significant space change detected${NC}"
    fi
}

# --- Function to check sudo access ---
check_sudo_access() {
    if ! sudo -v; then
        echo -e "${RED}Error: This script requires sudo privileges.${NC}"
        log_action "ERROR: Sudo access denied"
        exit 1
    fi
    log_action "Script started with sudo access"
}

# --- Function to check for command existence ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Function to validate user input ---
validate_input() {
    local input=$1
    local valid_options=$2
    local prompt=$3

    while true; do
        read -p "$prompt" input
        if [ -z "$input" ]; then
            echo ""
            return 0
        elif [[ "$valid_options" =~ "$input" ]]; then
            echo "$input"
            return 0
        else
            echo -e "${RED}Invalid format. Please use a number followed by a unit.${NC}"
            echo -e "${BLUE}Valid time units: d (days), w (weeks), month, months, y (years)${NC}"
            echo -e "${BLUE}Valid size units: M, MB (megabytes), G, GB (gigabytes)${NC}"
            echo -e "${BLUE}Examples: 1d, 2w, 1month, 100M, 500MB, 1G${NC}"
        fi
    done
}

# --- Progress bar for long operations ---
show_progress() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local completed=$((width * percentage / 100))
    local remaining=$((width - completed))

    # Build progress bar
    local progress_bar=""
    progress_bar+="${GREEN}["
    for ((i=0; i<completed; i++)); do
        progress_bar+="#"
    done
    for ((i=0; i<remaining; i++)); do
        progress_bar+=" "
    done
    progress_bar+="]${NC} "

    # Add percentage and status
    printf "\r%s %d%%" "$progress_bar" "$percentage"

    # Complete when done
    if [ $current -eq $total ]; then
        printf "\n"
    fi
}

# --- System health check ---
check_system_health() {
    print_separator
    echo -e "${GREEN}System Health Check${NC}"
    print_separator

    local issues=0

    # Check disk space
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 95 ]; then
        echo -e "${RED}⚠ CRITICAL: Disk space critically low (${disk_usage}% used)${NC}"
        issues=$((issues + 1))
    elif [ "$disk_usage" -gt 85 ]; then
        echo -e "${YELLOW}⚠ WARNING: Disk space low (${disk_usage}% used)${NC}"
        issues=$((issues + 1))
    fi

    # Check available memory
    local mem_available=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    if [ "$mem_available" -lt 500 ]; then
        echo -e "${RED}⚠ CRITICAL: Low available memory (${mem_available}MB)${NC}"
        issues=$((issues + 1))
    elif [ "$mem_available" -lt 1000 ]; then
        echo -e "${YELLOW}⚠ WARNING: Low available memory (${mem_available}MB)${NC}"
        issues=$((issues + 1))
    fi

    # Check for running package managers
    if pgrep -x "apt" > /dev/null; then
        echo -e "${YELLOW}⚠ WARNING: Package manager (apt) is running${NC}"
        echo -e "${BLUE}   Please close package managers before running cleanup${NC}"
        issues=$((issues + 1))
    fi

    # Check for large log files
    local large_logs=$(find /var/log -type f -size +100M 2>/dev/null | wc -l)
    if [ "$large_logs" -gt 0 ]; then
        echo -e "${YELLOW}⚠ INFO: Found $large_logs large log files (>100MB)${NC}"
        echo -e "${BLUE}   These can be cleaned in the System Journal cleanup step${NC}"
    fi

    # Summary
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}✓ System health check passed - no issues detected${NC}"
    else
        echo -e "\n${YELLOW}Found $issues potential issue(s). Review warnings above before proceeding.${NC}"
        read -p "Continue anyway? [y/N] " confirm
        if ! [[ $confirm =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Exiting due to system health concerns.${NC}"
            log_action "Script exited due to system health issues"
            exit 0
        fi
    fi

    log_action "System health check completed - $issues issues found"
}

# --- Function to check Ubuntu version ---
check_ubuntu_version() {
    if ! command_exists lsb_release; then
        echo -e "${RED}Error: 'lsb_release' not found. Cannot verify Ubuntu version.${NC}"
        log_action "ERROR: lsb_release not found - cannot verify Ubuntu version"
        exit 1
    fi
    version=$(lsb_release -rs)
    if [[ "$version" != "24.04" ]]; then
        echo -e "${YELLOW}Warning: This script is optimized for Ubuntu 24.04. Current version: $version. Proceed with caution.${NC}"
        log_action "WARNING: Running on Ubuntu $version (optimized for 24.04)"
        read -p "Continue anyway? [y/N] " confirm
        if ! [[ $confirm =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Exiting.${NC}"
            log_action "User declined to run on Ubuntu $version - script exited"
            exit 0
        fi
        log_action "User confirmed to proceed on Ubuntu $version"
    else
        log_action "Ubuntu version verified: $version"
    fi
}

# --- 1. Update System ---
update_system() {
    print_separator
    echo -e "${GREEN}Step 1: Updating package lists and upgrading packages...${NC}"
    print_separator

    # Track space before update
    local space_before=$(get_available_space)
    log_action "System update started"

    # Update package lists with error handling
    echo -e "${YELLOW}Updating package lists...${NC}"
    if ! sudo apt update; then
        echo -e "${RED}Error: Failed to update package lists. Check your internet connection or package sources.${NC}"
        log_action "ERROR: Failed to update package lists"
        return 1
    fi
    log_action "Package lists updated successfully"

    # Count upgradable packages
    echo -e "\n${YELLOW}Checking for available updates...${NC}"
    upgradable_count=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    
    # Handle case when system is already up-to-date
    if [ "$upgradable_count" -eq 0 ]; then
        echo -e "${GREEN}System is already up-to-date. No packages need upgrading.${NC}"
        log_action "System already up-to-date"
        return 0
    fi

    # Display upgradable package count
    echo -e "${BLUE}Found ${upgradable_count} package(s) available for upgrade.${NC}"
    log_action "Found $upgradable_count upgradable packages"

    # Show disk space requirements using simulation
    echo -e "\n${YELLOW}Calculating disk space requirements...${NC}"
    apt -s full-upgrade 2>/dev/null | grep "^After this operation"
    
    # Display list of upgradable packages
    echo -e "\n${BLUE}Packages to be upgraded:${NC}"
    apt list --upgradable 2>/dev/null | grep upgradable | head -20
    if [ "$upgradable_count" -gt 20 ]; then
        echo -e "${BLUE}... and $((upgradable_count - 20)) more packages${NC}"
    fi

    # Add confirmation prompt before upgrade
    echo ""
    read -p "Do you want to proceed with the upgrade? [y/N] " confirm
    if ! [[ $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}System upgrade cancelled.${NC}"
        log_action "System upgrade cancelled by user"
        return 0
    fi

    # Perform the upgrade
    echo -e "\n${YELLOW}Performing system upgrade...${NC}"
    if ! sudo apt full-upgrade -y; then
        echo -e "${RED}Error: Failed to upgrade packages. Some updates may have failed.${NC}"
        log_action "ERROR: System upgrade failed"
        return 1
    fi
    
    echo -e "${GREEN}System upgrade complete.${NC}"
    log_action "System upgrade completed successfully"

    # Check for reboot requirement
    if [ -f /var/run/reboot-required ]; then
        echo -e "\n${YELLOW}============================================================${NC}"
        echo -e "${YELLOW}  SYSTEM REBOOT REQUIRED${NC}"
        echo -e "${YELLOW}============================================================${NC}"
        echo -e "${BLUE}Some updates require a system reboot to take effect.${NC}"
        
        if [ -f /var/run/reboot-required.pkgs ]; then
            echo -e "\n${BLUE}Packages requiring reboot:${NC}"
            cat /var/run/reboot-required.pkgs
        fi
        
        echo ""
        read -p "Do you want to reboot now? [y/N] " reboot_confirm
        if [[ $reboot_confirm =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Rebooting system...${NC}"
            log_action "System reboot initiated by user"
            sudo reboot
        else
            echo -e "${YELLOW}Reboot postponed. Please remember to reboot your system later.${NC}"
            log_action "Reboot required but postponed by user"
        fi
    fi

    # Track space after update
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 2. APT Package Cleanup ---
cleanup_apt() {
    print_separator
    echo -e "${GREEN}Step 2: APT Package Cleanup${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "APT cleanup started"

    # Autoremove
    echo -e "${YELLOW}Checking for packages that are no longer required...${NC}"
    if apt autoremove --dry-run | grep -q 'Remv'; then
        apt autoremove --dry-run
        read -p "Do you want to remove these packages? [y/N] " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            if ! sudo apt autoremove -y; then
                echo -e "${RED}Error: Failed to remove unused packages. Check for broken dependencies.${NC}"
                log_action "ERROR: APT autoremove failed"
                return 1
            fi
            echo -e "${GREEN}Unused packages removed.${NC}"
            log_action "APT autoremove completed"
        else
            echo -e "${YELLOW}Autoremove cancelled.${NC}"
            log_action "APT autoremove cancelled by user"
        fi
    else
        echo -e "${BLUE}No unused packages to remove.${NC}"
        log_action "No unused packages found"
    fi

    # Autoclean
    echo -e "\n${YELLOW}Cleaning up old package cache...${NC}"
    if ! sudo apt autoclean; then
        echo -e "${RED}Error: Failed to clean package cache.${NC}"
        log_action "ERROR: APT autoclean failed"
        return 1
    fi
    echo -e "${GREEN}Package cache cleaned.${NC}"
    log_action "APT autoclean completed"

    # Purge residual configs
    echo -e "\n${YELLOW}Checking for residual configuration files...${NC}"
    residual_configs=$(dpkg -l | grep '^rc' | awk '{print $2}')
    if [ -n "$residual_configs" ]; then
        echo -e "${BLUE}The following packages have residual config files:${NC}"
        echo "$residual_configs"
        read -p "Do you want to purge these configuration files? [y/N] " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            if ! sudo apt purge "$residual_configs" -y; then
                echo -e "${RED}Error: Failed to purge residual configuration files.${NC}"
                log_action "ERROR: APT purge failed"
                return 1
            fi
            echo -e "${GREEN}Residual configuration files purged.${NC}"
            log_action "Residual configs purged"
        else
            echo -e "${YELLOW}Purge cancelled.${NC}"
            log_action "Residual config purge cancelled by user"
        fi
    else
        echo -e "${BLUE}No residual configuration files found.${NC}"
        log_action "No residual configs found"
    fi

    # Track space after cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 3. System Journal Cleanup ---
cleanup_logs() {
    print_separator
    echo -e "${GREEN}Step 3: System Journal (Logs) Cleanup${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "Journal cleanup started"

    journalctl --disk-usage
    echo -e "\n${YELLOW}You can limit logs by time or size.${NC}"
    echo -e "${BLUE}Time formats: 1d, 2w, 1month, 3months, 1y${NC}"
    echo -e "${BLUE}Size formats: 100M, 500MB, 1G, 2GB${NC}"
    vacuum_option=$(validate_input "" "^[0-9]+[a-zA-Z]+$" "Enter vacuum time or size, or press Enter to skip: ")
    if [ -n "$vacuum_option" ]; then
        log_action "Journal vacuum option set to: $vacuum_option"
        
        # Let journalctl handle the actual validation
        # Try vacuum-time first, then vacuum-size
        if sudo journalctl --vacuum-time="$vacuum_option" 2>/dev/null; then
            echo -e "${GREEN}Journal logs vacuumed to '$vacuum_option'.${NC}"
            log_action "Journal logs vacuumed to $vacuum_option (time-based)"
        elif sudo journalctl --vacuum-size="$vacuum_option" 2>/dev/null; then
            echo -e "${GREEN}Journal logs vacuumed to '$vacuum_option'.${NC}"
            log_action "Journal logs vacuumed to $vacuum_option (size-based)"
        else
            echo -e "${RED}Error: Failed to vacuum logs with '$vacuum_option'.${NC}"
            echo -e "${YELLOW}Please check the format and try again.${NC}"
            echo -e "${BLUE}Valid time units: d, w, month, months, y${NC}"
            echo -e "${BLUE}Valid size units: M, MB, G, GB${NC}"
            log_action "ERROR: Failed to vacuum journal logs with: $vacuum_option"
            return 1
        fi
    else
        echo -e "${YELLOW}Log cleanup skipped.${NC}"
        log_action "Journal cleanup skipped by user"
    fi

    # Track space after cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 4. User-Level Cleanup ---
cleanup_user_cache() {
    print_separator
    echo -e "${GREEN}Step 4: User-Level Cleanup (Trash, Thumbnails)${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "User-level cleanup started"

    # Trash
    if [ -d ~/.local/share/Trash/files ] && [ "$(ls -A ~/.local/share/Trash/files)" ]; then
        # Calculate trash size using du -sh
        echo -e "${YELLOW}Calculating trash size...${NC}"
        trash_size=$(du -sh ~/.local/share/Trash/files 2>/dev/null | awk '{print $1}')
        
        # Count files in trash using find and wc -l
        trash_file_count=$(find ~/.local/share/Trash/files -type f 2>/dev/null | wc -l)
        
        # Display trash size and file count to user
        echo -e "${BLUE}Trash contains ${trash_file_count} file(s) using ${trash_size} of disk space.${NC}"
        log_action "Trash size: $trash_size ($trash_file_count files)"
        
        read -p "Do you want to empty the trash? [y/N] " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Add secondary confirmation if trash size exceeds 1GB
            trash_size_bytes=$(du -sb ~/.local/share/Trash/files 2>/dev/null | awk '{print $1}')
            one_gb=$((1024 * 1024 * 1024))
            
            if [ "$trash_size_bytes" -gt "$one_gb" ]; then
                echo -e "${YELLOW}WARNING: Trash size exceeds 1GB (${trash_size}).${NC}"
                read -p "Are you sure you want to permanently delete these files? [y/N] " secondary_confirm
                if ! [[ $secondary_confirm =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}Trash emptying cancelled.${NC}"
                    log_action "Trash emptying cancelled by user (secondary confirmation)"
                    return 0
                fi
            fi
            
            rm -rf ~/.local/share/Trash/files/*
            echo -e "${GREEN}Trash emptied.${NC}"
            log_action "Trash emptied: $trash_size ($trash_file_count files)"
        else
            echo -e "${YELLOW}Trash emptying cancelled.${NC}"
            log_action "Trash emptying cancelled by user"
        fi
    else
        echo -e "${BLUE}Trash is already empty.${NC}"
        log_action "Trash already empty"
    fi

    # Thumbnails
    if [ -d ~/.cache/thumbnails ]; then
        echo -e "\n${YELLOW}Cleaning up thumbnail cache...${NC}"
        rm -rf ~/.cache/thumbnails/*
        echo -e "${GREEN}Thumbnail cache cleaned.${NC}"
        log_action "Thumbnail cache cleaned"
    fi

    # Track space after cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 5. Flatpak and Snap Cleanup ---
cleanup_sandboxed() {
    print_separator
    echo -e "${GREEN}Step 5: Flatpak and Snap Cleanup${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "Sandboxed apps cleanup started"

    # Flatpak
    if command_exists flatpak; then
        echo -e "${YELLOW}Checking for unused Flatpak runtimes...${NC}"
        if flatpak uninstall --unused --dry-run | grep -q 'ID'; then
            flatpak uninstall --unused --dry-run
            read -p "Do you want to remove these unused Flatpak items? [y/N] " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                flatpak uninstall --unused -y
                echo -e "${GREEN}Unused Flatpak items removed.${NC}"
                log_action "Unused Flatpak items removed"
            else
                echo -e "${YELLOW}Flatpak cleanup cancelled.${NC}"
                log_action "Flatpak cleanup cancelled by user"
            fi
        else
            echo -e "${BLUE}No unused Flatpak items found.${NC}"
            log_action "No unused Flatpak items found"
        fi
    else
        echo -e "${BLUE}Flatpak is not installed.${NC}"
        log_action "Flatpak not installed"
    fi

    # Snap
    if command_exists snap; then
        echo -e "\n${YELLOW}Checking for old, disabled Snap revisions...${NC}"
        old_snaps=$(snap list --all | awk '/disabled/{print $1, $3}')
        if [ -n "$old_snaps" ]; then
            echo -e "${BLUE}The following disabled Snap revisions will be removed:${NC}"
            echo "$old_snaps"
            read -p "Do you want to remove them? [y/N] " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo "$old_snaps" | while read -r snapname revision; do
                    sudo snap remove "$snapname" --revision="$revision"
                done
                echo -e "${GREEN}Old Snap revisions removed.${NC}"
                log_action "Old Snap revisions removed"
            else
                echo -e "${YELLOW}Snap cleanup cancelled.${NC}"
                log_action "Snap cleanup cancelled by user"
            fi
        else
            echo -e "${BLUE}No old Snap revisions found.${NC}"
            log_action "No old Snap revisions found"
        fi
    else
        echo -e "${BLUE}Snap is not installed.${NC}"
        log_action "Snap not installed"
    fi

    # Track space after cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 6. Interactive AppImage Cleanup ---
cleanup_appimages() {
    print_separator
    echo -e "${GREEN}Step 6: Interactive AppImage Cleanup${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "AppImage cleanup started"

    # Add more comprehensive AppImage search
    find_appimages() {
        local appimage_paths=(
            "$HOME/Applications"
            "$HOME/.local/bin"
            "$HOME/bin"
            "/opt"
            "/usr/local/bin"
            "$HOME/Downloads"
        )

        local found_appimages=()

        for path in "${appimage_paths[@]}"; do
            if [ -d "$path" ]; then
                while IFS= read -r -d '' appimage; do
                    found_appimages+=("$appimage")
                done < <(find "$path" -name "*.AppImage" -type f -print0 2>/dev/null)
            fi
        done

        echo "${found_appimages[@]}"
    }

    echo -e "${YELLOW}Searching for AppImage files in common locations...${NC}"
    
    # Use mapfile to store AppImage files in array
    declare -a appimage_files
    mapfile -t appimage_files < <(find_appimages)
    
    # Handle case when no AppImages are found
    if [ ${#appimage_files[@]} -eq 0 ]; then
        echo -e "${BLUE}No AppImage files found in your home directory.${NC}"
        log_action "No AppImage files found"
        return 0
    fi
    
    # Calculate size for each AppImage and check executable status
    declare -a appimage_sizes
    declare -a appimage_exec
    local total_size_bytes=0
    
    echo -e "${BLUE}Analyzing AppImage files...${NC}"
    for appimage in "${appimage_files[@]}"; do
        # Calculate size using du -h
        size=$(du -h "$appimage" 2>/dev/null | awk '{print $1}')
        appimage_sizes+=("$size")
        
        # Get size in bytes for total calculation
        size_bytes=$(du -b "$appimage" 2>/dev/null | awk '{print $1}')
        total_size_bytes=$((total_size_bytes + size_bytes))
        
        # Check executable status using test -x
        if [ -x "$appimage" ]; then
            appimage_exec+=("executable")
        else
            appimage_exec+=("not executable")
        fi
    done
    
    # Calculate and display total size of all AppImages
    local total_size_human=$(echo "$total_size_bytes" | awk '{
        if ($1 >= 1073741824) printf "%.1fGB", $1/1073741824;
        else if ($1 >= 1048576) printf "%.1fMB", $1/1048576;
        else if ($1 >= 1024) printf "%.1fKB", $1/1024;
        else printf "%dB", $1;
    }')
    
    # Display numbered list with path, size, and executable status
    echo -e "\n${GREEN}Found ${#appimage_files[@]} AppImage file(s) (Total: ${total_size_human})${NC}\n"
    for i in "${!appimage_files[@]}"; do
        local num=$((i + 1))
        echo -e "  ${YELLOW}${num})${NC} ${appimage_files[$i]}"
        echo -e "      Size: ${appimage_sizes[$i]} | Status: ${appimage_exec[$i]}"
    done
    
    # Provide interactive menu: [a]ll, [s]elect by number, [n]one
    echo -e "\n${BLUE}Options:${NC}"
    echo -e "  ${YELLOW}[a]${NC} Remove all AppImages"
    echo -e "  ${YELLOW}[s]${NC} Select specific AppImages by number (comma-separated, e.g., 1,3,5)"
    echo -e "  ${YELLOW}[n]${NC} Skip AppImage cleanup"
    echo ""
    read -p "Enter your choice: " choice
    
    case $choice in
        a|A)
            # Implement "remove all" option with confirmation
            echo -e "\n${RED}WARNING: This will permanently delete all ${#appimage_files[@]} AppImage files (${total_size_human}).${NC}"
            read -p "Are you sure you want to remove ALL AppImages? [y/N] " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                local removed_count=0
                for appimage in "${appimage_files[@]}"; do
                    if rm -f "$appimage" 2>/dev/null; then
                        removed_count=$((removed_count + 1))
                        log_action "Removed AppImage: $appimage"
                    else
                        echo -e "${RED}Failed to remove: $appimage${NC}"
                        log_action "ERROR: Failed to remove AppImage: $appimage"
                    fi
                done
                echo -e "${GREEN}Successfully removed ${removed_count} AppImage file(s).${NC}"
                log_action "Removed $removed_count AppImage files (total: ${total_size_human})"
            else
                echo -e "${YELLOW}AppImage removal cancelled.${NC}"
                log_action "AppImage removal cancelled by user"
            fi
            ;;
        s|S)
            # Implement selective removal by parsing comma-separated numbers
            read -p "Enter AppImage numbers to remove (comma-separated, e.g., 1,3,5): " numbers
            
            # Validate number inputs and handle invalid entries
            IFS=',' read -ra selected_nums <<< "$numbers"
            declare -a valid_indices
            declare -a invalid_entries
            
            for num in "${selected_nums[@]}"; do
                # Trim whitespace
                num=$(echo "$num" | xargs)
                
                # Check if it's a valid number
                if [[ "$num" =~ ^[0-9]+$ ]]; then
                    local index=$((num - 1))
                    # Check if index is within valid range
                    if [ "$index" -ge 0 ] && [ "$index" -lt "${#appimage_files[@]}" ]; then
                        valid_indices+=("$index")
                    else
                        invalid_entries+=("$num")
                    fi
                else
                    invalid_entries+=("$num")
                fi
            done
            
            # Report invalid entries
            if [ ${#invalid_entries[@]} -gt 0 ]; then
                echo -e "${RED}Invalid entries: ${invalid_entries[*]}${NC}"
                echo -e "${BLUE}Valid range is 1-${#appimage_files[@]}${NC}"
            fi
            
            # Proceed with valid selections
            if [ ${#valid_indices[@]} -gt 0 ]; then
                echo -e "\n${BLUE}Selected AppImages for removal:${NC}"
                local selected_size_bytes=0
                for idx in "${valid_indices[@]}"; do
                    local num=$((idx + 1))
                    echo -e "  ${YELLOW}${num})${NC} ${appimage_files[$idx]} (${appimage_sizes[$idx]})"
                    # Calculate total size of selected files
                    local size_bytes=$(du -b "${appimage_files[$idx]}" 2>/dev/null | awk '{print $1}')
                    selected_size_bytes=$((selected_size_bytes + size_bytes))
                done
                
                local selected_size_human=$(echo "$selected_size_bytes" | awk '{
                    if ($1 >= 1073741824) printf "%.1fGB", $1/1073741824;
                    else if ($1 >= 1048576) printf "%.1fMB", $1/1048576;
                    else if ($1 >= 1024) printf "%.1fKB", $1/1024;
                    else printf "%dB", $1;
                }')
                
                echo -e "\n${YELLOW}Total size to be freed: ${selected_size_human}${NC}"
                read -p "Confirm removal of these ${#valid_indices[@]} AppImage(s)? [y/N] " confirm
                
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    local removed_count=0
                    for idx in "${valid_indices[@]}"; do
                        if rm -f "${appimage_files[$idx]}" 2>/dev/null; then
                            removed_count=$((removed_count + 1))
                            log_action "Removed AppImage: ${appimage_files[$idx]}"
                        else
                            echo -e "${RED}Failed to remove: ${appimage_files[$idx]}${NC}"
                            log_action "ERROR: Failed to remove AppImage: ${appimage_files[$idx]}"
                        fi
                    done
                    echo -e "${GREEN}Successfully removed ${removed_count} AppImage file(s).${NC}"
                    log_action "Removed $removed_count selected AppImage files (${selected_size_human})"
                else
                    echo -e "${YELLOW}AppImage removal cancelled.${NC}"
                    log_action "AppImage removal cancelled by user"
                fi
            else
                echo -e "${YELLOW}No valid AppImages selected. Operation cancelled.${NC}"
                log_action "No valid AppImages selected"
            fi
            ;;
        n|N)
            echo -e "${YELLOW}AppImage cleanup skipped.${NC}"
            log_action "AppImage cleanup skipped by user"
            ;;
        *)
            echo -e "${RED}Invalid option. AppImage cleanup cancelled.${NC}"
            log_action "AppImage cleanup cancelled - invalid option"
            ;;
    esac
    
    # Track space after cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 7. Old Kernel Cleanup ---
cleanup_old_kernels() {
    print_separator
    echo -e "${GREEN}Step 7: Old Kernel Cleanup${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "Old kernel cleanup started"

    # Detect current running kernel using uname -r
    local current_kernel=$(uname -r)
    echo -e "${BLUE}Current running kernel: ${current_kernel}${NC}"
    log_action "Current kernel: $current_kernel"

    # List all installed kernels using dpkg -l and grep linux-image
    echo -e "\n${YELLOW}Scanning for installed kernel packages...${NC}"
    
    # Get kernel packages with enhanced detection
    get_kernel_packages() {
        local kernel_version=$1
        local packages=()

        # Primary kernel packages
        packages+=("linux-image-${kernel_version}")
        packages+=("linux-headers-${kernel_version}")
        packages+=("linux-modules-${kernel_version}")

        # Additional packages that might exist
        if dpkg -l | grep -q "linux-image-extra-${kernel_version}"; then
            packages+=("linux-image-extra-${kernel_version}")
        fi

        if dpkg -l | grep -q "linux-modules-extra-${kernel_version}"; then
            packages+=("linux-modules-extra-${kernel_version}")
        fi

        echo "${packages[@]}"
    }
    
    local all_kernels=$(dpkg -l | grep '^ii' | grep 'linux-image-[0-9]' | awk '{print $2}' | grep -v 'linux-image-generic')
    
    if [ -z "$all_kernels" ]; then
        echo -e "${BLUE}No additional kernel packages found to clean up.${NC}"
        log_action "No additional kernel packages found"
        return 0
    fi

    # Parse and sort kernel versions
    # Extract version numbers and sort them
    local sorted_kernels=$(echo "$all_kernels" | sed 's/linux-image-//' | sort -V)
    
    # Build list of removable kernels (exclude current kernel)
    declare -a removable_kernels
    declare -a removable_sizes
    local current_kernel_pkg="linux-image-${current_kernel}"
    local total_size_bytes=0
    local kept_count=0
    
    # Convert sorted kernels back to package names and filter
    echo -e "${YELLOW}Analyzing kernel packages...${NC}"
    while IFS= read -r kernel_version; do
        local kernel_pkg="linux-image-${kernel_version}"
        
        # Skip if this is the current kernel
        if [ "$kernel_pkg" = "$current_kernel_pkg" ]; then
            echo -e "${GREEN}  ✓ Keeping current kernel: ${kernel_pkg}${NC}"
            log_action "Keeping current kernel: $kernel_pkg"
            continue
        fi
        
        # Keep at least one previous kernel version for safety
        if [ $kept_count -lt 1 ]; then
            echo -e "${GREEN}  ✓ Keeping previous kernel for safety: ${kernel_pkg}${NC}"
            log_action "Keeping previous kernel: $kernel_pkg"
            kept_count=$((kept_count + 1))
            continue
        fi
        
        # Calculate disk space used by each removable kernel
        # Include related packages (headers, modules)
        local kernel_base=$(echo "$kernel_version" | sed 's/-generic$//')
        local related_packages=$(dpkg -l | grep "^ii" | grep "$kernel_base" | awk '{print $2}' | tr '\n' ' ')
        
        if [ -n "$related_packages" ]; then
            # Calculate size of all related packages
            local size_bytes=0
            for pkg in $related_packages; do
                local pkg_size=$(dpkg-query -W -f='${Installed-Size}\n' "$pkg" 2>/dev/null || echo "0")
                size_bytes=$((size_bytes + pkg_size))
            done
            
            # Convert KB to human-readable format
            local size_human
            if [ $size_bytes -ge 1048576 ]; then
                size_human=$(awk "BEGIN {printf \"%.1fGB\", $size_bytes/1048576}")
            else
                size_human=$(awk "BEGIN {printf \"%.1fMB\", $size_bytes/1024}")
            fi
            
            removable_kernels+=("$kernel_pkg")
            removable_sizes+=("$size_human")
            total_size_bytes=$((total_size_bytes + size_bytes))
        fi
    done <<< "$sorted_kernels"
    
    # Display list of removable kernels with sizes
    if [ ${#removable_kernels[@]} -eq 0 ]; then
        echo -e "\n${BLUE}No old kernels to remove. System is already clean.${NC}"
        echo -e "${BLUE}Current kernel and one previous version are being kept for safety.${NC}"
        log_action "No old kernels to remove"
        return 0
    fi
    
    # Calculate total size
    local total_size_human
    if [ $total_size_bytes -ge 1048576 ]; then
        total_size_human=$(awk "BEGIN {printf \"%.1fGB\", $total_size_bytes/1048576}")
    else
        total_size_human=$(awk "BEGIN {printf \"%.1fMB\", $total_size_bytes/1024}")
    fi
    
    echo -e "\n${YELLOW}Old kernels that can be removed (Total: ${total_size_human}):${NC}"
    for i in "${!removable_kernels[@]}"; do
        local num=$((i + 1))
        echo -e "  ${YELLOW}${num})${NC} ${removable_kernels[$i]} (${removable_sizes[$i]})"
    done
    
    # Require user confirmation before removal
    echo -e "\n${BLUE}Note: Current kernel and one previous version will be kept for safety.${NC}"
    echo -e "${RED}WARNING: Removing kernels will free up space but you won't be able to boot into removed versions.${NC}"
    read -p "Do you want to remove these old kernel packages? [y/N] " confirm
    
    if ! [[ $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Kernel cleanup cancelled.${NC}"
        log_action "Kernel cleanup cancelled by user"
        return 0
    fi
    
    # Remove old kernels using sudo apt purge
    echo -e "\n${YELLOW}Removing old kernel packages...${NC}"
    local removed_count=0
    local failed_count=0
    
    for kernel_pkg in "${removable_kernels[@]}"; do
        # Get all related packages for this kernel version
        local kernel_base=$(echo "$kernel_pkg" | sed 's/linux-image-//' | sed 's/-generic$//')
        local related_packages=$(dpkg -l | grep "^ii" | grep "$kernel_base" | awk '{print $2}' | tr '\n' ' ')
        
        echo -e "${BLUE}Removing: $related_packages${NC}"
        if sudo apt purge -y $related_packages 2>/dev/null; then
            removed_count=$((removed_count + 1))
            log_action "Removed kernel packages: $related_packages"
        else
            echo -e "${RED}Failed to remove: $kernel_pkg${NC}"
            log_action "ERROR: Failed to remove kernel: $kernel_pkg"
            failed_count=$((failed_count + 1))
        fi
    done
    
    # Summary
    if [ $removed_count -gt 0 ]; then
        echo -e "\n${GREEN}Successfully removed ${removed_count} old kernel package(s).${NC}"
        log_action "Removed $removed_count old kernel packages (${total_size_human})"
        
        # Run autoremove to clean up any remaining dependencies
        echo -e "${YELLOW}Cleaning up remaining dependencies...${NC}"
        sudo apt autoremove -y
    fi
    
    if [ $failed_count -gt 0 ]; then
        echo -e "${YELLOW}Warning: ${failed_count} kernel package(s) could not be removed.${NC}"
    fi

    # Track space after cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 8. Docker Cleanup ---
cleanup_docker() {
    print_separator
    echo -e "${GREEN}Step 8: Docker Cleanup${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "Docker cleanup started"

    # Check if Docker is installed using command_exists
    if ! command_exists docker; then
        echo -e "${BLUE}Docker is not installed on this system. Skipping Docker cleanup.${NC}"
        log_action "Docker not installed - cleanup skipped"
        return 0
    fi

    # Verify Docker daemon is running using docker info
    echo -e "${YELLOW}Checking Docker daemon status...${NC}"
    if ! sudo docker info >/dev/null 2>&1; then
        echo -e "${RED}Docker daemon is not running or accessible.${NC}"
        echo -e "${BLUE}Troubleshooting steps:${NC}"
        echo -e "  1. Check if Docker is installed: docker --version"
        echo -e "  2. Start Docker service: sudo systemctl start docker"
        echo -e "  3. Check Docker status: sudo systemctl status docker"
        echo -e "  4. Add user to docker group: sudo usermod -aG docker \$USER"
        echo -e "${YELLOW}Please resolve these issues before continuing.${NC}"
        log_action "ERROR: Docker daemon not accessible - user notified"
        return 1
    fi

    # Display Docker disk usage using docker system df
    echo -e "\n${BLUE}Current Docker disk usage:${NC}"
    sudo docker system df
    echo ""
    log_action "Docker disk usage displayed"

    # Show usage breakdown: containers, images, volumes
    echo -e "${YELLOW}Detailed breakdown:${NC}"
    
    # Count containers
    local total_containers=$(sudo docker ps -a -q | wc -l)
    local stopped_containers=$(sudo docker ps -a -q -f status=exited | wc -l)
    echo -e "  Containers: ${total_containers} total (${stopped_containers} stopped)"
    
    # Count images
    local total_images=$(sudo docker images -q | wc -l)
    local dangling_images=$(sudo docker images -q -f dangling=true | wc -l)
    echo -e "  Images: ${total_images} total (${dangling_images} dangling)"
    
    # Count volumes
    local total_volumes=$(sudo docker volume ls -q | wc -l)
    local unused_volumes=$(sudo docker volume ls -q -f dangling=true | wc -l)
    echo -e "  Volumes: ${total_volumes} total (${unused_volumes} unused)"
    
    # Provide menu options: remove containers, remove images, remove volumes, prune all, skip
    echo -e "\n${BLUE}Docker Cleanup Options:${NC}"
    echo -e "  ${YELLOW}1)${NC} Remove stopped containers"
    echo -e "  ${YELLOW}2)${NC} Remove unused images (dangling)"
    echo -e "  ${YELLOW}3)${NC} Remove all unused images (not just dangling)"
    echo -e "  ${YELLOW}4)${NC} Remove unused volumes"
    echo -e "  ${YELLOW}5)${NC} Prune all unused Docker data (containers, images, volumes, networks)"
    echo -e "  ${YELLOW}6)${NC} Skip Docker cleanup"
    echo ""
    read -p "Enter your choice (1-6): " docker_choice

    case $docker_choice in
        1)
            # Implement removal of stopped containers
            if [ "$stopped_containers" -eq 0 ]; then
                echo -e "${BLUE}No stopped containers to remove.${NC}"
                log_action "No stopped containers found"
            else
                echo -e "\n${YELLOW}Stopped containers:${NC}"
                sudo docker ps -a -f status=exited --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
                echo ""
                
                # Add confirmation prompts for each operation
                read -p "Remove all stopped containers? [y/N] " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}Removing stopped containers...${NC}"
                    if sudo docker container prune -f; then
                        echo -e "${GREEN}Stopped containers removed successfully.${NC}"
                        log_action "Removed stopped containers"
                    else
                        echo -e "${RED}Error: Failed to remove stopped containers.${NC}"
                        log_action "ERROR: Failed to remove stopped containers"
                    fi
                else
                    echo -e "${YELLOW}Container removal cancelled.${NC}"
                    log_action "Container removal cancelled by user"
                fi
            fi
            ;;
        2)
            # Implement removal of unused images (dangling)
            if [ "$dangling_images" -eq 0 ]; then
                echo -e "${BLUE}No dangling images to remove.${NC}"
                log_action "No dangling images found"
            else
                echo -e "\n${YELLOW}Dangling images (untagged):${NC}"
                sudo docker images -f dangling=true
                echo ""
                
                read -p "Remove all dangling images? [y/N] " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}Removing dangling images...${NC}"
                    if sudo docker image prune -f; then
                        echo -e "${GREEN}Dangling images removed successfully.${NC}"
                        log_action "Removed dangling images"
                    else
                        echo -e "${RED}Error: Failed to remove dangling images.${NC}"
                        log_action "ERROR: Failed to remove dangling images"
                    fi
                else
                    echo -e "${YELLOW}Image removal cancelled.${NC}"
                    log_action "Image removal cancelled by user"
                fi
            fi
            ;;
        3)
            # Implement removal of all unused images
            echo -e "\n${YELLOW}This will remove ALL images not associated with a container.${NC}"
            echo -e "${RED}WARNING: This may remove images you want to keep!${NC}"
            sudo docker images
            echo ""
            
            read -p "Remove all unused images? [y/N] " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Removing all unused images...${NC}"
                if sudo docker image prune -a -f; then
                    echo -e "${GREEN}Unused images removed successfully.${NC}"
                    log_action "Removed all unused images"
                else
                    echo -e "${RED}Error: Failed to remove unused images.${NC}"
                    log_action "ERROR: Failed to remove unused images"
                fi
            else
                echo -e "${YELLOW}Image removal cancelled.${NC}"
                log_action "All unused images removal cancelled by user"
            fi
            ;;
        4)
            # Implement removal of unused volumes
            if [ "$unused_volumes" -eq 0 ]; then
                echo -e "${BLUE}No unused volumes to remove.${NC}"
                log_action "No unused volumes found"
            else
                echo -e "\n${YELLOW}Unused volumes:${NC}"
                sudo docker volume ls -f dangling=true
                echo ""
                echo -e "${RED}WARNING: Removing volumes will permanently delete data!${NC}"
                
                read -p "Remove all unused volumes? [y/N] " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}Removing unused volumes...${NC}"
                    if sudo docker volume prune -f; then
                        echo -e "${GREEN}Unused volumes removed successfully.${NC}"
                        log_action "Removed unused volumes"
                    else
                        echo -e "${RED}Error: Failed to remove unused volumes.${NC}"
                        log_action "ERROR: Failed to remove unused volumes"
                    fi
                else
                    echo -e "${YELLOW}Volume removal cancelled.${NC}"
                    log_action "Volume removal cancelled by user"
                fi
            fi
            ;;
        5)
            # Implement system-wide prune option
            echo -e "\n${RED}WARNING: This will remove:${NC}"
            echo -e "  - All stopped containers"
            echo -e "  - All networks not used by at least one container"
            echo -e "  - All dangling images"
            echo -e "  - All dangling build cache"
            echo -e "\n${YELLOW}Current Docker disk usage:${NC}"
            sudo docker system df
            echo ""
            
            read -p "Proceed with system-wide Docker prune? [y/N] " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Performing system-wide Docker cleanup...${NC}"
                if sudo docker system prune -f; then
                    echo -e "${GREEN}Docker system prune completed successfully.${NC}"
                    log_action "Docker system prune completed"
                    
                    # Optionally offer to prune volumes too
                    echo -e "\n${YELLOW}Do you also want to prune unused volumes?${NC}"
                    echo -e "${RED}WARNING: This will permanently delete volume data!${NC}"
                    read -p "Prune volumes? [y/N] " volume_confirm
                    if [[ $volume_confirm =~ ^[Yy]$ ]]; then
                        if sudo docker volume prune -f; then
                            echo -e "${GREEN}Unused volumes pruned successfully.${NC}"
                            log_action "Docker volumes pruned"
                        else
                            echo -e "${RED}Error: Failed to prune volumes.${NC}"
                            log_action "ERROR: Failed to prune volumes"
                        fi
                    fi
                else
                    echo -e "${RED}Error: Failed to complete system prune.${NC}"
                    log_action "ERROR: Docker system prune failed"
                fi
            else
                echo -e "${YELLOW}System prune cancelled.${NC}"
                log_action "Docker system prune cancelled by user"
            fi
            ;;
        6)
            echo -e "${YELLOW}Docker cleanup skipped.${NC}"
            log_action "Docker cleanup skipped by user"
            ;;
        *)
            echo -e "${RED}Invalid option. Docker cleanup cancelled.${NC}"
            log_action "Docker cleanup cancelled - invalid option"
            ;;
    esac

    # Add space tracking to Docker cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 9. Browser Cache Cleanup ---
cleanup_browser_cache() {
    print_separator
    echo -e "${GREEN}Step 9: Browser Cache Cleanup${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "Browser cache cleanup started"

    # Detect browsers with enhanced detection
    detect_browsers() {
        local detected_browsers=()

        # Firefox (including multiple profiles)
        if [ -d "$HOME/.mozilla/firefox" ]; then
            detected_browsers+=("Firefox")
        fi

        # Chrome/Chromium-based browsers
        for browser in "google-chrome" "chromium" "brave-browser" "vivaldi-stable" "opera"; do
            if [ -d "$HOME/.cache/$browser" ]; then
                detected_browsers+=("$browser")
            fi
        done

        # Flatpak browsers
        if command_exists flatpak; then
            flatpak_browsers=$(flatpak list --app | grep -E "(firefox|chrome|chromium|brave)" | awk '{print $1}')
            if [ -n "$flatpak_browsers" ]; then
                detected_browsers+=("Flatpak: $flatpak_browsers")
            fi
        fi

        echo "${detected_browsers[@]}"
    }

    # Define cache paths for Firefox, Chrome, Chromium, and Brave
    declare -A browser_paths
    browser_paths["Firefox"]="$HOME/.mozilla/firefox"
    browser_paths["Chrome"]="$HOME/.cache/google-chrome"
    browser_paths["Chromium"]="$HOME/.cache/chromium"
    browser_paths["Brave"]="$HOME/.cache/BraveSoftware/Brave-Browser"

    # Detect which browsers are installed by checking cache directories
    declare -a detected_browsers
    declare -a browser_cache_sizes
    declare -a browser_cache_paths
    local total_cache_bytes=0

    echo -e "${YELLOW}Detecting installed browsers...${NC}"
    
    # Check Firefox (handle multiple profiles)
    if [ -d "${browser_paths["Firefox"]}" ]; then
        local firefox_profiles=$(find "${browser_paths["Firefox"]}" -maxdepth 1 -type d -name "*.default*" 2>/dev/null)
        if [ -n "$firefox_profiles" ]; then
            local firefox_cache_size=0
            local firefox_cache_paths_list=""
            
            while IFS= read -r profile; do
                local cache_dir="$profile/cache2"
                if [ -d "$cache_dir" ]; then
                    local cache_bytes=$(du -sb "$cache_dir" 2>/dev/null | awk '{print $1}')
                    firefox_cache_size=$((firefox_cache_size + cache_bytes))
                    firefox_cache_paths_list="$firefox_cache_paths_list $cache_dir"
                fi
            done <<< "$firefox_profiles"
            
            if [ $firefox_cache_size -gt 0 ]; then
                local size_human=$(echo "$firefox_cache_size" | awk '{
                    if ($1 >= 1073741824) printf "%.1fGB", $1/1073741824;
                    else if ($1 >= 1048576) printf "%.1fMB", $1/1048576;
                    else if ($1 >= 1024) printf "%.1fKB", $1/1024;
                    else printf "%dB", $1;
                }')
                detected_browsers+=("Firefox")
                browser_cache_sizes+=("$size_human")
                browser_cache_paths+=("$firefox_cache_paths_list")
                total_cache_bytes=$((total_cache_bytes + firefox_cache_size))
            fi
        fi
    fi

    # Check Chrome
    if [ -d "${browser_paths["Chrome"]}" ]; then
        local chrome_cache="${browser_paths["Chrome"]}/Default/Cache"
        if [ -d "$chrome_cache" ] || [ -d "${browser_paths["Chrome"]}/Default/Code Cache" ]; then
            local cache_bytes=$(du -sb "${browser_paths["Chrome"]}" 2>/dev/null | awk '{print $1}')
            if [ $cache_bytes -gt 0 ]; then
                local size_human=$(echo "$cache_bytes" | awk '{
                    if ($1 >= 1073741824) printf "%.1fGB", $1/1073741824;
                    else if ($1 >= 1048576) printf "%.1fMB", $1/1048576;
                    else if ($1 >= 1024) printf "%.1fKB", $1/1024;
                    else printf "%dB", $1;
                }')
                detected_browsers+=("Chrome")
                browser_cache_sizes+=("$size_human")
                browser_cache_paths+=("${browser_paths["Chrome"]}")
                total_cache_bytes=$((total_cache_bytes + cache_bytes))
            fi
        fi
    fi

    # Check Chromium
    if [ -d "${browser_paths["Chromium"]}" ]; then
        local chromium_cache="${browser_paths["Chromium"]}/Default/Cache"
        if [ -d "$chromium_cache" ] || [ -d "${browser_paths["Chromium"]}/Default/Code Cache" ]; then
            local cache_bytes=$(du -sb "${browser_paths["Chromium"]}" 2>/dev/null | awk '{print $1}')
            if [ $cache_bytes -gt 0 ]; then
                local size_human=$(echo "$cache_bytes" | awk '{
                    if ($1 >= 1073741824) printf "%.1fGB", $1/1073741824;
                    else if ($1 >= 1048576) printf "%.1fMB", $1/1048576;
                    else if ($1 >= 1024) printf "%.1fKB", $1/1024;
                    else printf "%dB", $1;
                }')
                detected_browsers+=("Chromium")
                browser_cache_sizes+=("$size_human")
                browser_cache_paths+=("${browser_paths["Chromium"]}")
                total_cache_bytes=$((total_cache_bytes + cache_bytes))
            fi
        fi
    fi

    # Check Brave
    if [ -d "${browser_paths["Brave"]}" ]; then
        local brave_cache="${browser_paths["Brave"]}/Default/Cache"
        if [ -d "$brave_cache" ] || [ -d "${browser_paths["Brave"]}/Default/Code Cache" ]; then
            local cache_bytes=$(du -sb "${browser_paths["Brave"]}" 2>/dev/null | awk '{print $1}')
            if [ $cache_bytes -gt 0 ]; then
                local size_human=$(echo "$cache_bytes" | awk '{
                    if ($1 >= 1073741824) printf "%.1fGB", $1/1073741824;
                    else if ($1 >= 1048576) printf "%.1fMB", $1/1048576;
                    else if ($1 >= 1024) printf "%.1fKB", $1/1024;
                    else printf "%dB", $1;
                }')
                detected_browsers+=("Brave")
                browser_cache_sizes+=("$size_human")
                browser_cache_paths+=("${browser_paths["Brave"]}")
                total_cache_bytes=$((total_cache_bytes + cache_bytes))
            fi
        fi
    fi

    # Handle case when no browsers are detected
    if [ ${#detected_browsers[@]} -eq 0 ]; then
        echo -e "${BLUE}No browser caches found or all browser caches are empty.${NC}"
        log_action "No browser caches detected"
        return 0
    fi

    # Calculate and display total cache size
    local total_size_human=$(echo "$total_cache_bytes" | awk '{
        if ($1 >= 1073741824) printf "%.1fGB", $1/1073741824;
        else if ($1 >= 1048576) printf "%.1fMB", $1/1048576;
        else if ($1 >= 1024) printf "%.1fKB", $1/1024;
        else printf "%dB", $1;
    }')

    # Display list of browsers with cache sizes
    echo -e "\n${GREEN}Detected browser caches (Total: ${total_size_human}):${NC}\n"
    for i in "${!detected_browsers[@]}"; do
        local num=$((i + 1))
        echo -e "  ${YELLOW}${num})${NC} ${detected_browsers[$i]} - ${browser_cache_sizes[$i]}"
    done

    # Warn user to close browsers before cleanup
    echo -e "\n${RED}⚠ WARNING: Please close all browsers before proceeding!${NC}"
    echo -e "${YELLOW}Cleaning browser caches while browsers are running may cause issues.${NC}"

    # Provide selective cleanup options by browser
    echo -e "\n${BLUE}Browser Cache Cleanup Options:${NC}"
    echo -e "  ${YELLOW}[a]${NC} Clean all browser caches"
    echo -e "  ${YELLOW}[s]${NC} Select specific browsers by number (comma-separated, e.g., 1,3)"
    echo -e "  ${YELLOW}[n]${NC} Skip browser cache cleanup"
    echo ""
    read -p "Enter your choice: " choice

    case $choice in
        a|A)
            # Clean all browser caches
            echo -e "\n${YELLOW}This will clean caches for all detected browsers (${total_size_human}).${NC}"
            read -p "Are you sure you want to clean all browser caches? [y/N] " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                local cleaned_count=0
                for i in "${!detected_browsers[@]}"; do
                    local browser="${detected_browsers[$i]}"
                    local cache_path="${browser_cache_paths[$i]}"
                    
                    echo -e "${YELLOW}Cleaning ${browser} cache...${NC}"
                    
                    # Remove selected browser caches
                    if [ "$browser" = "Firefox" ]; then
                        # Handle Firefox multiple profiles
                        for cache_dir in $cache_path; do
                            if rm -rf "$cache_dir"/* 2>/dev/null; then
                                log_action "Cleaned Firefox cache: $cache_dir"
                            else
                                echo -e "${RED}Failed to clean: $cache_dir${NC}"
                                log_action "ERROR: Failed to clean Firefox cache: $cache_dir"
                            fi
                        done
                        cleaned_count=$((cleaned_count + 1))
                    else
                        # For Chrome, Chromium, Brave - clean the entire cache directory
                        if rm -rf "$cache_path"/* 2>/dev/null; then
                            cleaned_count=$((cleaned_count + 1))
                            log_action "Cleaned ${browser} cache: $cache_path"
                        else
                            echo -e "${RED}Failed to clean ${browser} cache${NC}"
                            log_action "ERROR: Failed to clean ${browser} cache: $cache_path"
                        fi
                    fi
                done
                echo -e "${GREEN}Successfully cleaned ${cleaned_count} browser cache(s).${NC}"
                log_action "Cleaned $cleaned_count browser caches (total: ${total_size_human})"
            else
                echo -e "${YELLOW}Browser cache cleanup cancelled.${NC}"
                log_action "Browser cache cleanup cancelled by user"
            fi
            ;;
        s|S)
            # Select specific browsers
            read -p "Enter browser numbers to clean (comma-separated, e.g., 1,3): " numbers
            
            # Validate number inputs
            IFS=',' read -ra selected_nums <<< "$numbers"
            declare -a valid_indices
            declare -a invalid_entries
            
            for num in "${selected_nums[@]}"; do
                # Trim whitespace
                num=$(echo "$num" | xargs)
                
                # Check if it's a valid number
                if [[ "$num" =~ ^[0-9]+$ ]]; then
                    local index=$((num - 1))
                    # Check if index is within valid range
                    if [ "$index" -ge 0 ] && [ "$index" -lt "${#detected_browsers[@]}" ]; then
                        valid_indices+=("$index")
                    else
                        invalid_entries+=("$num")
                    fi
                else
                    invalid_entries+=("$num")
                fi
            done
            
            # Report invalid entries
            if [ ${#invalid_entries[@]} -gt 0 ]; then
                echo -e "${RED}Invalid entries: ${invalid_entries[*]}${NC}"
                echo -e "${BLUE}Valid range is 1-${#detected_browsers[@]}${NC}"
            fi
            
            # Proceed with valid selections
            if [ ${#valid_indices[@]} -gt 0 ]; then
                echo -e "\n${BLUE}Selected browsers for cache cleanup:${NC}"
                local selected_size_bytes=0
                for idx in "${valid_indices[@]}"; do
                    local num=$((idx + 1))
                    echo -e "  ${YELLOW}${num})${NC} ${detected_browsers[$idx]} (${browser_cache_sizes[$idx]})"
                done
                
                echo ""
                read -p "Confirm cleaning these browser caches? [y/N] " confirm
                
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    local cleaned_count=0
                    for idx in "${valid_indices[@]}"; do
                        local browser="${detected_browsers[$idx]}"
                        local cache_path="${browser_cache_paths[$idx]}"
                        
                        echo -e "${YELLOW}Cleaning ${browser} cache...${NC}"
                        
                        # Remove selected browser caches
                        if [ "$browser" = "Firefox" ]; then
                            # Handle Firefox multiple profiles
                            for cache_dir in $cache_path; do
                                if rm -rf "$cache_dir"/* 2>/dev/null; then
                                    log_action "Cleaned Firefox cache: $cache_dir"
                                else
                                    echo -e "${RED}Failed to clean: $cache_dir${NC}"
                                    log_action "ERROR: Failed to clean Firefox cache: $cache_dir"
                                fi
                            done
                            cleaned_count=$((cleaned_count + 1))
                        else
                            # For Chrome, Chromium, Brave
                            if rm -rf "$cache_path"/* 2>/dev/null; then
                                cleaned_count=$((cleaned_count + 1))
                                log_action "Cleaned ${browser} cache: $cache_path"
                            else
                                echo -e "${RED}Failed to clean ${browser} cache${NC}"
                                log_action "ERROR: Failed to clean ${browser} cache: $cache_path"
                            fi
                        fi
                    done
                    echo -e "${GREEN}Successfully cleaned ${cleaned_count} browser cache(s).${NC}"
                    log_action "Cleaned $cleaned_count selected browser caches"
                else
                    echo -e "${YELLOW}Browser cache cleanup cancelled.${NC}"
                    log_action "Browser cache cleanup cancelled by user"
                fi
            else
                echo -e "${YELLOW}No valid browsers selected. Operation cancelled.${NC}"
                log_action "No valid browsers selected"
            fi
            ;;
        n|N)
            echo -e "${YELLOW}Browser cache cleanup skipped.${NC}"
            log_action "Browser cache cleanup skipped by user"
            ;;
        *)
            echo -e "${RED}Invalid option. Browser cache cleanup cancelled.${NC}"
            log_action "Browser cache cleanup cancelled - invalid option"
            ;;
    esac

    # Add space tracking to browser cache cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 10. User Cache Directory Management ---
cleanup_cache_directory() {
    print_separator
    echo -e "${GREEN}Step 10: User Cache Directory Management${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "User cache directory cleanup started"

    # Check if ~/.cache directory exists
    if [ ! -d ~/.cache ]; then
        echo -e "${BLUE}Cache directory (~/.cache) does not exist.${NC}"
        log_action "Cache directory not found"
        return 0
    fi

    # Calculate total ~/.cache directory size using du -sh
    echo -e "${YELLOW}Calculating cache directory size...${NC}"
    local total_cache_size=$(du -sh ~/.cache 2>/dev/null | awk '{print $1}')
    echo -e "${BLUE}Total cache directory size: ${total_cache_size}${NC}"
    log_action "Cache directory size: $total_cache_size"

    # List cache subdirectories sorted by size using du and sort
    # Exclude thumbnails directory from listing
    echo -e "\n${YELLOW}Analyzing cache subdirectories...${NC}"
    
    # Get cache subdirectories, exclude thumbnails, sort by size, get top 10
    local cache_list=$(du -sh ~/.cache/* 2>/dev/null | grep -v "thumbnails$" | sort -hr | head -10)
    
    if [ -z "$cache_list" ]; then
        echo -e "${BLUE}No cache subdirectories found to clean.${NC}"
        log_action "No cache subdirectories found"
        return 0
    fi

    # Display top 10 largest cache folders with sizes
    echo -e "\n${GREEN}Top 10 largest cache folders:${NC}\n"
    
    declare -a cache_dirs
    declare -a cache_sizes
    local index=0
    
    while IFS=$'\t' read -r size dir; do
        index=$((index + 1))
        cache_dirs+=("$dir")
        cache_sizes+=("$size")
        
        # Extract directory name for display
        local dir_name=$(basename "$dir")
        echo -e "  ${YELLOW}${index})${NC} ${dir_name} - ${size}"
        
        # Add warnings for application-critical caches
        case "$dir_name" in
            fontconfig)
                echo -e "      ${RED}⚠ WARNING: Font cache - may cause font rendering issues${NC}"
                ;;
            mesa_shader_cache)
                echo -e "      ${RED}⚠ WARNING: Graphics shader cache - may affect graphics performance${NC}"
                ;;
            nvidia)
                echo -e "      ${RED}⚠ WARNING: NVIDIA cache - may affect graphics performance${NC}"
                ;;
            gstreamer-*)
                echo -e "      ${YELLOW}⚠ CAUTION: Media framework cache - will be rebuilt on use${NC}"
                ;;
            pip)
                echo -e "      ${BLUE}ℹ INFO: Python pip cache - safe to remove, will be rebuilt${NC}"
                ;;
        esac
    done <<< "$cache_list"

    # Provide options to clean specific cache folders
    echo -e "\n${BLUE}Cache Directory Cleanup Options:${NC}"
    echo -e "  ${YELLOW}[a]${NC} Clean all listed cache folders"
    echo -e "  ${YELLOW}[s]${NC} Select specific folders by number (comma-separated, e.g., 1,3,5)"
    echo -e "  ${YELLOW}[n]${NC} Skip cache directory cleanup"
    echo ""
    read -p "Enter your choice: " choice

    case $choice in
        a|A)
            # Clean all cache folders
            echo -e "\n${RED}WARNING: This will remove all listed cache folders (${total_cache_size}).${NC}"
            echo -e "${YELLOW}Application-critical caches will be rebuilt automatically but may cause temporary slowdowns.${NC}"
            
            # Implement selective removal with confirmation
            read -p "Are you sure you want to clean all listed cache folders? [y/N] " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                local cleaned_count=0
                local failed_count=0
                
                for dir in "${cache_dirs[@]}"; do
                    local dir_name=$(basename "$dir")
                    echo -e "${YELLOW}Cleaning ${dir_name}...${NC}"
                    
                    if rm -rf "$dir"/* 2>/dev/null; then
                        cleaned_count=$((cleaned_count + 1))
                        log_action "Cleaned cache directory: $dir"
                    else
                        echo -e "${RED}Failed to clean: ${dir_name}${NC}"
                        log_action "ERROR: Failed to clean cache directory: $dir"
                        failed_count=$((failed_count + 1))
                    fi
                done
                
                echo -e "${GREEN}Successfully cleaned ${cleaned_count} cache folder(s).${NC}"
                if [ $failed_count -gt 0 ]; then
                    echo -e "${YELLOW}Warning: ${failed_count} folder(s) could not be cleaned.${NC}"
                fi
                log_action "Cleaned $cleaned_count cache directories"
            else
                echo -e "${YELLOW}Cache directory cleanup cancelled.${NC}"
                log_action "Cache directory cleanup cancelled by user"
            fi
            ;;
        s|S)
            # Select specific cache folders
            read -p "Enter folder numbers to clean (comma-separated, e.g., 1,3,5): " numbers
            
            # Validate number inputs
            IFS=',' read -ra selected_nums <<< "$numbers"
            declare -a valid_indices
            declare -a invalid_entries
            
            for num in "${selected_nums[@]}"; do
                # Trim whitespace
                num=$(echo "$num" | xargs)
                
                # Check if it's a valid number
                if [[ "$num" =~ ^[0-9]+$ ]]; then
                    local idx=$((num - 1))
                    # Check if index is within valid range
                    if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#cache_dirs[@]}" ]; then
                        valid_indices+=("$idx")
                    else
                        invalid_entries+=("$num")
                    fi
                else
                    invalid_entries+=("$num")
                fi
            done
            
            # Report invalid entries
            if [ ${#invalid_entries[@]} -gt 0 ]; then
                echo -e "${RED}Invalid entries: ${invalid_entries[*]}${NC}"
                echo -e "${BLUE}Valid range is 1-${#cache_dirs[@]}${NC}"
            fi
            
            # Proceed with valid selections
            if [ ${#valid_indices[@]} -gt 0 ]; then
                echo -e "\n${BLUE}Selected cache folders for cleanup:${NC}"
                local has_critical=0
                
                for idx in "${valid_indices[@]}"; do
                    local num=$((idx + 1))
                    local dir_name=$(basename "${cache_dirs[$idx]}")
                    echo -e "  ${YELLOW}${num})${NC} ${dir_name} (${cache_sizes[$idx]})"
                    
                    # Check for critical caches
                    case "$dir_name" in
                        fontconfig|mesa_shader_cache|nvidia)
                            has_critical=1
                            ;;
                    esac
                done
                
                # Add warnings for application-critical caches
                if [ $has_critical -eq 1 ]; then
                    echo -e "\n${RED}⚠ WARNING: You have selected application-critical caches.${NC}"
                    echo -e "${YELLOW}These will be rebuilt automatically but may cause temporary issues.${NC}"
                fi
                
                echo ""
                read -p "Confirm cleaning these cache folders? [y/N] " confirm
                
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    local cleaned_count=0
                    local failed_count=0
                    
                    for idx in "${valid_indices[@]}"; do
                        local dir="${cache_dirs[$idx]}"
                        local dir_name=$(basename "$dir")
                        echo -e "${YELLOW}Cleaning ${dir_name}...${NC}"
                        
                        if rm -rf "$dir"/* 2>/dev/null; then
                            cleaned_count=$((cleaned_count + 1))
                            log_action "Cleaned cache directory: $dir"
                        else
                            echo -e "${RED}Failed to clean: ${dir_name}${NC}"
                            log_action "ERROR: Failed to clean cache directory: $dir"
                            failed_count=$((failed_count + 1))
                        fi
                    done
                    
                    echo -e "${GREEN}Successfully cleaned ${cleaned_count} cache folder(s).${NC}"
                    if [ $failed_count -gt 0 ]; then
                        echo -e "${YELLOW}Warning: ${failed_count} folder(s) could not be cleaned.${NC}"
                    fi
                    log_action "Cleaned $cleaned_count selected cache directories"
                else
                    echo -e "${YELLOW}Cache directory cleanup cancelled.${NC}"
                    log_action "Cache directory cleanup cancelled by user"
                fi
            else
                echo -e "${YELLOW}No valid cache folders selected. Operation cancelled.${NC}"
                log_action "No valid cache folders selected"
            fi
            ;;
        n|N)
            echo -e "${YELLOW}Cache directory cleanup skipped.${NC}"
            log_action "Cache directory cleanup skipped by user"
            ;;
        *)
            echo -e "${RED}Invalid option. Cache directory cleanup cancelled.${NC}"
            log_action "Cache directory cleanup cancelled - invalid option"
            ;;
    esac

    # Add space tracking to cache directory cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 11. System Coredump Cleanup ---
cleanup_coredumps() {
    print_separator
    echo -e "${GREEN}Step 11: System Coredump Cleanup${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "Coredump cleanup started"

    # Check if /var/lib/systemd/coredump directory exists
    local coredump_dir="/var/lib/systemd/coredump"
    
    if [ ! -d "$coredump_dir" ]; then
        echo -e "${BLUE}Coredump directory does not exist. No coredumps to clean.${NC}"
        log_action "Coredump directory not found"
        return 0
    fi

    # Check if there are any coredump files
    local coredump_count=$(sudo find "$coredump_dir" -type f 2>/dev/null | wc -l)
    
    if [ "$coredump_count" -eq 0 ]; then
        echo -e "${BLUE}No coredump files found. Directory is empty.${NC}"
        log_action "No coredump files found"
        return 0
    fi

    # Calculate total size of coredump files using du -sh
    echo -e "${YELLOW}Analyzing coredump files...${NC}"
    local coredump_size=$(sudo du -sh "$coredump_dir" 2>/dev/null | awk '{print $1}')
    
    # Display coredump size to user
    echo -e "${BLUE}Found ${coredump_count} coredump file(s) using ${coredump_size} of disk space.${NC}"
    log_action "Coredump size: $coredump_size ($coredump_count files)"

    # List coredump files with timestamps
    echo -e "\n${YELLOW}Coredump files:${NC}"
    sudo ls -lh "$coredump_dir" 2>/dev/null | tail -n +2 | head -10
    
    if [ "$coredump_count" -gt 10 ]; then
        echo -e "${BLUE}... and $((coredump_count - 10)) more files${NC}"
    fi

    # Require user confirmation before removal
    echo -e "\n${YELLOW}Coredumps are crash dumps from failed applications.${NC}"
    echo -e "${BLUE}They are typically only needed for debugging purposes.${NC}"
    echo ""
    read -p "Do you want to remove all coredump files? [y/N] " confirm
    
    if ! [[ $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Coredump cleanup cancelled.${NC}"
        log_action "Coredump cleanup cancelled by user"
        return 0
    fi

    # Use sudo to remove coredump files
    echo -e "${YELLOW}Removing coredump files...${NC}"
    if sudo rm -rf "$coredump_dir"/* 2>/dev/null; then
        echo -e "${GREEN}Successfully removed ${coredump_count} coredump file(s).${NC}"
        log_action "Removed $coredump_count coredump files ($coredump_size)"
    else
        echo -e "${RED}Error: Failed to remove coredump files. Check permissions.${NC}"
        log_action "ERROR: Failed to remove coredump files"
        return 1
    fi

    # Add space tracking to coredump cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 12. Python Package Cache Cleanup ---
cleanup_pip_cache() {
    print_separator
    echo -e "${GREEN}Step 12: Python Package Cache Cleanup${NC}"
    print_separator

    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "Pip cache cleanup started"

    # Check if pip3 is installed using command_exists
    if ! command_exists pip3; then
        echo -e "${BLUE}pip3 is not installed on this system. Skipping pip cache cleanup.${NC}"
        log_action "pip3 not installed - cleanup skipped"
        return 0
    fi

    # Check if pip cache directory exists
    local pip_cache_dir="$HOME/.cache/pip"
    
    if [ ! -d "$pip_cache_dir" ]; then
        echo -e "${BLUE}Pip cache directory does not exist or is empty.${NC}"
        log_action "Pip cache directory not found"
        return 0
    fi

    # Calculate pip cache size using du -sh ~/.cache/pip
    echo -e "${YELLOW}Calculating pip cache size...${NC}"
    local pip_cache_size=$(du -sh "$pip_cache_dir" 2>/dev/null | awk '{print $1}')
    
    # Check if cache is empty
    local cache_bytes=$(du -sb "$pip_cache_dir" 2>/dev/null | awk '{print $1}')
    if [ "$cache_bytes" -eq 0 ] || [ -z "$cache_bytes" ]; then
        echo -e "${BLUE}Pip cache is empty. Nothing to clean.${NC}"
        log_action "Pip cache is empty"
        return 0
    fi

    # Display pip cache size to user
    echo -e "${BLUE}Python pip cache size: ${pip_cache_size}${NC}"
    log_action "Pip cache size: $pip_cache_size"

    echo -e "\n${YELLOW}The pip cache stores downloaded Python packages for faster reinstallation.${NC}"
    echo -e "${BLUE}It is safe to remove and will be rebuilt automatically when needed.${NC}"

    # Offer to purge pip cache
    echo ""
    read -p "Do you want to purge the pip cache? [y/N] " confirm
    
    if ! [[ $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Pip cache cleanup cancelled.${NC}"
        log_action "Pip cache cleanup cancelled by user"
        return 0
    fi

    # Execute pip3 cache purge command on confirmation
    echo -e "${YELLOW}Purging pip cache...${NC}"
    
    # Handle both pip and pip3 commands
    local purge_success=0
    
    # Try pip3 first
    if pip3 cache purge 2>/dev/null; then
        purge_success=1
        echo -e "${GREEN}Successfully purged pip3 cache.${NC}"
        log_action "Purged pip3 cache ($pip_cache_size)"
    else
        # Try pip if pip3 fails
        if command_exists pip && pip cache purge 2>/dev/null; then
            purge_success=1
            echo -e "${GREEN}Successfully purged pip cache.${NC}"
            log_action "Purged pip cache ($pip_cache_size)"
        fi
    fi
    
    if [ $purge_success -eq 0 ]; then
        echo -e "${RED}Error: Failed to purge pip cache. You may need to update pip.${NC}"
        echo -e "${YELLOW}Trying manual cleanup...${NC}"
        
        # Fallback: manual removal
        if rm -rf "$pip_cache_dir"/* 2>/dev/null; then
            echo -e "${GREEN}Successfully cleaned pip cache directory manually.${NC}"
            log_action "Manually cleaned pip cache ($pip_cache_size)"
        else
            echo -e "${RED}Error: Failed to clean pip cache. Check permissions.${NC}"
            log_action "ERROR: Failed to clean pip cache"
            return 1
        fi
    fi

    # Add space tracking to pip cache cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- 13. Advanced: Remove Orphaned Libraries ---
cleanup_orphans() {
    print_separator
    echo -e "${GREEN}Step 13: Advanced - Find Orphaned Libraries (using deborphan)${NC}"
    print_separator
    
    # Track space before cleanup
    local space_before=$(get_available_space)
    log_action "Orphaned libraries cleanup started"
    
    echo -e "${RED}WARNING: This step removes potentially unused libraries. Misidentification can break software. Only proceed if you're experienced.${NC}"
    read -p "Do you want to continue with this advanced step? [y/N] " proceed
    if ! [[ $proceed =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Orphan cleanup skipped.${NC}"
        log_action "Orphan cleanup skipped by user"
        return 0
    fi
    
    log_action "User confirmed orphan cleanup - proceeding with caution"
    
    if ! command_exists deborphan; then
        echo -e "${YELLOW}'deborphan' is not installed. Installing it now...${NC}"
        log_action "Installing deborphan tool"
        if ! sudo apt install deborphan -y; then
            echo -e "${RED}Error: Failed to install deborphan.${NC}"
            log_action "ERROR: Failed to install deborphan"
            return 1
        fi
        log_action "deborphan installed successfully"
    fi
    
    orphaned_packages=$(deborphan 2>/dev/null)
    if [ -n "$orphaned_packages" ]; then
        local orphan_count=$(echo "$orphaned_packages" | wc -l)
        echo -e "${BLUE}The following libraries appear to be orphaned:${NC}"
        echo "$orphaned_packages"
        log_action "Found $orphan_count orphaned packages"
        
        echo -e "\n${RED}WARNING: Review the list carefully. Removing wrong packages can cause issues.${NC}"
        read -p "Do you want to purge these orphaned packages? [y/N] " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            log_action "User confirmed removal of $orphan_count orphaned packages"
            if echo "$orphaned_packages" | xargs -r sudo apt-get -y remove --purge; then
                echo -e "${GREEN}Orphaned packages purged.${NC}"
                log_action "Successfully purged $orphan_count orphaned packages"
            else
                echo -e "${RED}Error: Failed to remove some packages. Check for dependencies.${NC}"
                log_action "ERROR: Failed to remove some orphaned packages"
            fi
        else
            echo -e "${YELLOW}Orphan removal cancelled.${NC}"
            log_action "Orphan removal cancelled by user"
        fi
    else
        echo -e "${BLUE}No orphaned packages found.${NC}"
        log_action "No orphaned packages found"
    fi
    
    # Track space after cleanup
    local space_after=$(get_available_space)
    show_space_saved "$space_before" "$space_after"
}

# --- View Log ---
view_log() {
    print_separator
    echo -e "${GREEN}Viewing Cleanup Log${NC}"
    print_separator
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "${BLUE}Log file: $LOG_FILE${NC}"
        echo -e "${YELLOW}Press 'q' to exit the log viewer${NC}\n"
        sleep 1
        less "$LOG_FILE"
        log_action "Log file viewed"
    else
        echo -e "${BLUE}No log file found. Logs will be created when cleanup operations are performed.${NC}"
        echo -e "${BLUE}Log location: $LOG_FILE${NC}"
        log_action "Attempted to view log - file does not exist yet"
    fi
}

# --- Clear Log ---
clear_log() {
    print_separator
    echo -e "${GREEN}Clear Cleanup Log${NC}"
    print_separator
    
    if [ -f "$LOG_FILE" ]; then
        local log_size=$(du -h "$LOG_FILE" | awk '{print $1}')
        echo -e "${YELLOW}Current log file size: ${log_size}${NC}"
        echo -e "${YELLOW}Log file location: $LOG_FILE${NC}"
        echo -e "${RED}WARNING: This will permanently delete the cleanup log.${NC}"
        read -p "Are you sure you want to clear the log file? [y/N] " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            if rm -f "$LOG_FILE"; then
                echo -e "${GREEN}Log file cleared successfully.${NC}"
                # Create new log file with cleared message
                log_action "Log file cleared by user"
            else
                echo -e "${RED}Error: Failed to clear log file.${NC}"
                log_action "ERROR: Failed to clear log file"
            fi
        else
            echo -e "${YELLOW}Log clearing cancelled.${NC}"
            log_action "Log clearing cancelled by user"
        fi
    else
        echo -e "${BLUE}No log file found. Nothing to clear.${NC}"
        echo -e "${BLUE}Log location: $LOG_FILE${NC}"
    fi
}


# --- Main Menu ---
show_menu() {
    clear
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}          Interactive Ubuntu 24.04 Cleanup Tool v2.0      ${NC}"
    echo -e "${GREEN}============================================================${NC}"
    
    # Add disk usage calculation for root partition at menu top
    # Calculate usage percentage and available space using df
    local root_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    local root_avail=$(df -h / | awk 'NR==2 {print $4}')
    local root_used=$(df -h / | awk 'NR==2 {print $3}')
    
    # Implement color coding: red if >90%, yellow if >75%, green otherwise
    local usage_color
    if [ "$root_usage" -gt 90 ]; then
        usage_color=$RED
    elif [ "$root_usage" -gt 75 ]; then
        usage_color=$YELLOW
    else
        usage_color=$GREEN
    fi
    
    echo -e "${usage_color}Disk Usage (/)${NC}: ${usage_color}${root_usage}%${NC} used (${root_used} / ${root_avail} available)"
    
    # Check for separate home partition and display if exists
    if df -h /home 2>/dev/null | grep -q "^/dev/" && ! df -h / | grep -q "$(df /home | awk 'NR==2 {print $1}')"; then
        local home_usage=$(df -h /home | awk 'NR==2 {print $5}' | sed 's/%//')
        local home_avail=$(df -h /home | awk 'NR==2 {print $4}')
        local home_used=$(df -h /home | awk 'NR==2 {print $3}')
        
        local home_color
        if [ "$home_usage" -gt 90 ]; then
            home_color=$RED
        elif [ "$home_usage" -gt 75 ]; then
            home_color=$YELLOW
        else
            home_color=$GREEN
        fi
        
        echo -e "${home_color}Disk Usage (/home)${NC}: ${home_color}${home_usage}%${NC} used (${home_used} / ${home_avail} available)"
    fi
    
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${BLUE}Standard Cleanup:${NC}"
    echo -e "  ${YELLOW}1)${NC} Update System"
    echo -e "  ${YELLOW}2)${NC} APT Package Cleanup"
    echo -e "  ${YELLOW}3)${NC} System Journal (Logs) Cleanup"
    echo -e "  ${YELLOW}4)${NC} User-Level Cleanup (Trash, Thumbnails)"
    echo -e "  ${YELLOW}5)${NC} Flatpak and Snap Cleanup"
    echo -e "  ${YELLOW}6)${NC} AppImage Management"
    echo -e "  ${YELLOW}7)${NC} Old Kernel Cleanup"
    echo -e "  ${YELLOW}8)${NC} Docker Cleanup"
    echo -e "  ${YELLOW}9)${NC} Browser Cache Cleanup"
    echo -e "  ${YELLOW}10)${NC} User Cache Directory Management"
    echo -e "  ${YELLOW}11)${NC} System Coredump Cleanup"
    echo -e "  ${YELLOW}12)${NC} Python Package Cache Cleanup"
    echo ""
    echo -e "${BLUE}Utilities:${NC}"
    echo -e "  ${YELLOW}l)${NC} View cleanup log"
    echo -e "  ${YELLOW}c)${NC} Clear log file"
    echo ""
    echo -e "${BLUE}Advanced (Use with caution):${NC}"
    echo -e "  ${YELLOW}x)${NC} Remove Orphaned Libraries"
    echo ""
    echo -e "${BLUE}Actions:${NC}"
    echo -e "  ${YELLOW}a)${NC} Run ALL standard cleanup steps"
    echo -e "  ${RED}q)${NC} Quit"
    echo -e "${GREEN}============================================================${NC}"
}


# --- Check sudo access at script start ---
check_sudo_access

# --- System health check at startup ---
check_system_health

# --- Main Loop ---
while true; do
    show_menu
    read -p "Enter your choice: " choice
    case $choice in
        1) log_action "User selected: Update System"; check_ubuntu_version; update_system ;;
        2) log_action "User selected: APT Package Cleanup"; cleanup_apt ;;
        3) log_action "User selected: System Journal Cleanup"; cleanup_logs ;;
        4) log_action "User selected: User-Level Cleanup"; cleanup_user_cache ;;
        5) log_action "User selected: Flatpak and Snap Cleanup"; cleanup_sandboxed ;;
        6) log_action "User selected: AppImage Management"; cleanup_appimages ;;
        7) log_action "User selected: Old Kernel Cleanup"; cleanup_old_kernels ;;
        8) log_action "User selected: Docker Cleanup"; cleanup_docker ;;
        9) log_action "User selected: Browser Cache Cleanup"; cleanup_browser_cache ;;
        10) log_action "User selected: User Cache Directory Management"; cleanup_cache_directory ;;
        11) log_action "User selected: System Coredump Cleanup"; cleanup_coredumps ;;
        12) log_action "User selected: Python Package Cache Cleanup"; cleanup_pip_cache ;;
        l|L) log_action "User selected: View cleanup log"; view_log ;;
        c|C) log_action "User selected: Clear log file"; clear_log ;;
        x|X) log_action "User selected: Remove Orphaned Libraries (Advanced)"; cleanup_orphans ;;
        a|A)
            # Run all standard cleanup steps with cumulative space tracking
            echo -e "\n${GREEN}============================================================${NC}"
            echo -e "${GREEN}  Running ALL Standard Cleanup Steps${NC}"
            echo -e "${GREEN}============================================================${NC}"
            
            # Track total space before all operations
            local total_space_before=$(get_available_space)
            log_action "Run all cleanup steps started - initial space: ${total_space_before}GB available"
            
            check_ubuntu_version
            update_system
            cleanup_apt
            cleanup_logs
            cleanup_user_cache
            cleanup_sandboxed
            cleanup_appimages
            cleanup_old_kernels
            cleanup_docker
            cleanup_browser_cache
            cleanup_cache_directory
            cleanup_coredumps
            cleanup_pip_cache
            
            # Track total space after all operations
            local total_space_after=$(get_available_space)
            local total_saved=$((total_space_after - total_space_before))
            
            # Display cumulative space savings
            echo -e "\n${GREEN}============================================================${NC}"
            echo -e "${GREEN}  All Standard Cleanup Steps Complete${NC}"
            echo -e "${GREEN}============================================================${NC}"
            
            if [ $total_saved -gt 0 ]; then
                echo -e "${GREEN}✓ Total space freed: ${total_saved}GB${NC}"
                log_action "Run all completed - Total space freed: ${total_saved}GB (from ${total_space_before}GB to ${total_space_after}GB)"
            else
                echo -e "${BLUE}No significant space change detected across all operations${NC}"
                log_action "Run all completed - No significant space change (${total_space_before}GB available)"
            fi
            
            echo -e "${BLUE}Note: Advanced orphan removal (Step x) was skipped for safety.${NC}"
            log_action "Run all completed - orphan removal skipped for safety"
            ;;
        q|Q)
            echo -e "${GREEN}Exiting. Goodbye!${NC}"
            log_action "Script exited by user"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            log_action "Invalid menu option entered: $choice"
            ;;
    esac
    read -p "Press [Enter] to return to the menu..."
done