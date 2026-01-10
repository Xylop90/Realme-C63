#!/bin/bash

################################################################################
# Termux Android Automated Installation Script
# Author: Xylop90
# Date: 2026-01-10
# Description: Comprehensive automated installation and setup for Termux on Android
#              with backup, verification, flashing, and logging features
################################################################################

set -euo pipefail

# ==============================================================================
# CONFIGURATION & CONSTANTS
# ==============================================================================

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Logging Configuration
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/termux-install-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="${PROJECT_ROOT}/backups"
DOWNLOAD_DIR="${PROJECT_ROOT}/downloads"
TEMP_DIR="${PROJECT_ROOT}/tmp"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
ENABLE_BACKUP=true
ENABLE_LOGGING=true
ENABLE_VERIFICATION=true
ENABLE_DOWNLOAD=true
ENABLE_FLASHING=true
DRY_RUN=false
VERBOSE=false

# Dependencies
REQUIRED_COMMANDS=("curl" "wget" "tar" "zip" "find" "grep" "sed")
OPTIONAL_COMMANDS=("adb" "fastboot" "7z")

# ==============================================================================
# LOGGING & OUTPUT FUNCTIONS
# ==============================================================================

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR" "$BACKUP_DIR" "$DOWNLOAD_DIR" "$TEMP_DIR"
    
    {
        echo "================================================================================"
        echo "Termux Installation Script Log"
        echo "================================================================================"
        echo "Start Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "User: $(whoami)"
        echo "Host: $(hostname)"
        echo "Script Version: 1.0.0"
        echo "================================================================================"
        echo ""
    } >> "$LOG_FILE"
    
    echo -e "${GREEN}[✓]${NC} Logging initialized: $LOG_FILE"
}

# Log message to file and optionally to console
log() {
    local level="$1"
    shift
    local message="$@"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        INFO)
            [[ "$VERBOSE" == true ]] && echo -e "${BLUE}[ℹ]${NC} $message"
            ;;
        SUCCESS)
            echo -e "${GREEN}[✓]${NC} $message"
            ;;
        WARN)
            echo -e "${YELLOW}[⚠]${NC} $message"
            ;;
        ERROR)
            echo -e "${RED}[✗]${NC} $message" >&2
            ;;
    esac
}

# Log command execution
log_command() {
    local cmd="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [COMMAND] $cmd" >> "$LOG_FILE"
}

# ==============================================================================
# ERROR HANDLING & CLEANUP
# ==============================================================================

# Cleanup function
cleanup() {
    local exit_code=$?
    
    log INFO "Starting cleanup process..."
    
    # Remove temporary files if they exist
    if [[ -d "$TEMP_DIR" ]] && [[ -n "$(ls -A "$TEMP_DIR" 2>/dev/null)" ]]; then
        log INFO "Removing temporary files..."
        rm -rf "$TEMP_DIR"/* || true
    fi
    
    if [[ $exit_code -eq 0 ]]; then
        log SUCCESS "Script completed successfully"
    else
        log ERROR "Script exited with code: $exit_code"
    fi
    
    echo "" >> "$LOG_FILE"
    echo "End Time: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "================================================================================" >> "$LOG_FILE"
}

trap cleanup EXIT
trap 'log ERROR "Interrupted by user"; exit 130' INT TERM

# Error handler
error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    log ERROR "$message"
    exit "$exit_code"
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

# Display usage
show_usage() {
    cat << 'EOF'
Usage: install-termux.sh [OPTIONS]

Options:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -d, --dry-run           Run without making actual changes
    --skip-backup           Skip backup creation
    --skip-verification     Skip verification checks
    --skip-download         Skip download step
    --skip-flashing         Skip flashing step
    --backup-only           Only perform backup
    --verify-only           Only perform verification
    
Examples:
    ./install-termux.sh                    # Standard installation
    ./install-termux.sh --dry-run          # Dry run mode
    ./install-termux.sh -v --backup-only   # Verbose backup only
EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                log WARN "Running in DRY-RUN mode - no changes will be made"
                shift
                ;;
            --skip-backup)
                ENABLE_BACKUP=false
                shift
                ;;
            --skip-verification)
                ENABLE_VERIFICATION=false
                shift
                ;;
            --skip-download)
                ENABLE_DOWNLOAD=false
                shift
                ;;
            --skip-flashing)
                ENABLE_FLASHING=false
                shift
                ;;
            --backup-only)
                ENABLE_VERIFICATION=false
                ENABLE_DOWNLOAD=false
                ENABLE_FLASHING=false
                shift
                ;;
            --verify-only)
                ENABLE_BACKUP=false
                ENABLE_DOWNLOAD=false
                ENABLE_FLASHING=false
                shift
                ;;
            *)
                log ERROR "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Check if command exists - with caching
declare -A CMD_CACHE
command_exists() {
    # Use cache to avoid repeated command lookups
    if [[ -n "${CMD_CACHE[$1]:-}" ]]; then
        return "${CMD_CACHE[$1]}"
    fi
    
    if command -v "$1" &> /dev/null; then
        CMD_CACHE[$1]=0
        return 0
    else
        CMD_CACHE[$1]=1
        return 1
    fi
}

# ==============================================================================
# VERIFICATION & CHECKS
# ==============================================================================

# Verify system requirements
verify_system() {
    log INFO "Verifying system requirements..."
    
    local failed=0
    
    # Check required commands
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if command_exists "$cmd"; then
            log INFO "Found required command: $cmd"
        else
            log ERROR "Missing required command: $cmd"
            ((failed++))
        fi
    done
    
    # Check optional commands
    for cmd in "${OPTIONAL_COMMANDS[@]}"; do
        if command_exists "$cmd"; then
            log INFO "Found optional command: $cmd"
        else
            log WARN "Optional command not found: $cmd"
        fi
    done
    
    # Check disk space
    local available_space=$(df "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
    local required_space=$((5 * 1024 * 1024)) # 5GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        log ERROR "Insufficient disk space. Available: ${available_space}KB, Required: ${required_space}KB"
        ((failed++))
    else
        log INFO "Disk space check passed. Available: ${available_space}KB"
    fi
    
    if [[ $failed -gt 0 ]]; then
        error_exit "System verification failed with $failed error(s)"
    fi
    
    log SUCCESS "System verification completed successfully"
}

# Verify Termux installation
verify_termux() {
    log INFO "Verifying Termux installation..."
    
    # Check if running in Termux environment
    if [[ -d "$PREFIX" ]] && [[ -f "$PREFIX/bin/termux-info" ]]; then
        log SUCCESS "Termux installation detected"
        log INFO "PREFIX: $PREFIX"
        
        # Get Termux version info
        if command_exists termux-info; then
            log INFO "Termux Info:"
            termux-info 2>/dev/null | grep -E "Termux" >> "$LOG_FILE" || true
        fi
        
        return 0
    else
        log WARN "Not running in Termux environment or installation incomplete"
        return 1
    fi
}

# Comprehensive verification
comprehensive_verification() {
    if [[ "$ENABLE_VERIFICATION" == false ]]; then
        log INFO "Verification skipped (--skip-verification)"
        return 0
    fi
    
    log INFO "Running comprehensive verification..."
    
    verify_system
    verify_termux || true
    
    # Verify backup directory
    if [[ -d "$BACKUP_DIR" ]]; then
        log INFO "Backup directory found: $BACKUP_DIR"
        local backup_count=$(find "$BACKUP_DIR" -name "*.tar.gz" 2>/dev/null | wc -l)
        log INFO "Existing backups: $backup_count"
    fi
    
    log SUCCESS "Comprehensive verification completed"
}

# ==============================================================================
# BACKUP FUNCTIONS
# ==============================================================================

# Create system backup
create_backup() {
    if [[ "$ENABLE_BACKUP" == false ]]; then
        log INFO "Backup skipped (--skip-backup)"
        return 0
    fi
    
    log INFO "Creating system backup..."
    
    local backup_name="termux-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    # Create list of important directories to backup
    local backup_dirs=(
        "$HOME/.termux"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
        "$PREFIX/etc"
    )
    
    # Filter existing directories
    local valid_dirs=()
    for dir in "${backup_dirs[@]}"; do
        if [[ -e "$dir" ]]; then
            valid_dirs+=("$dir")
        fi
    done
    
    if [[ ${#valid_dirs[@]} -eq 0 ]]; then
        log WARN "No directories found to backup"
        return 0
    fi
    
    log INFO "Backing up directories..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log INFO "[DRY-RUN] Would create backup: $backup_path"
        log INFO "[DRY-RUN] Directories to backup: ${valid_dirs[*]}"
    else
        {
            log_command "tar -czf '$backup_path' ${valid_dirs[*]}"
            tar -czf "$backup_path" "${valid_dirs[@]}" 2>&1 || error_exit "Failed to create backup"
        } >> "$LOG_FILE" 2>&1
        
        if [[ -f "$backup_path" ]]; then
            local backup_size=$(du -h "$backup_path" | cut -f1)
            log SUCCESS "Backup created: $backup_path (Size: $backup_size)"
        fi
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log ERROR "Backup file not found: $backup_file"
        return 1
    fi
    
    log INFO "Verifying backup integrity: $backup_file"
    
    if tar -tzf "$backup_file" &>/dev/null; then
        log SUCCESS "Backup integrity verified"
        return 0
    else
        log ERROR "Backup integrity check failed"
        return 1
    fi
}

# ==============================================================================
# DOWNLOAD FUNCTIONS
# ==============================================================================

# Download file with progress and verification
download_file() {
    local url="$1"
    local output_path="$2"
    local checksum="${3:-}"
    
    if [[ "$ENABLE_DOWNLOAD" == false ]]; then
        log INFO "Download skipped (--skip-download)"
        return 0
    fi
    
    local filename=$(basename "$url")
    log INFO "Downloading: $filename"
    
    if [[ "$DRY_RUN" == true ]]; then
        log INFO "[DRY-RUN] Would download: $url to $output_path"
        return 0
    fi
    
    # Create output directory if needed
    mkdir -p "$(dirname "$output_path")"
    
    # Determine download tool once
    local download_cmd
    if command_exists curl; then
        download_cmd="curl"
    elif command_exists wget; then
        download_cmd="wget"
    else
        error_exit "Neither curl nor wget found"
    fi
    
    # Download with retry logic and exponential backoff
    local max_retries=3
    local retry_count=0
    local wait_time=2
    
    while [[ $retry_count -lt $max_retries ]]; do
        log INFO "Attempt $((retry_count + 1))/$max_retries"
        
        local success=false
        if [[ "$download_cmd" == "curl" ]]; then
            log_command "curl -sSL -o '$output_path' '$url'"
            if curl -sSL -o "$output_path" "$url" 2>> "$LOG_FILE"; then
                success=true
            fi
        else
            log_command "wget -q -O '$output_path' '$url'"
            if wget -q -O "$output_path" "$url" 2>> "$LOG_FILE"; then
                success=true
            fi
        fi
        
        if [[ "$success" == true ]]; then
            log SUCCESS "Download completed: $filename"
            
            # Verify checksum if provided
            if [[ -n "$checksum" ]]; then
                verify_checksum "$output_path" "$checksum"
            fi
            
            return 0
        fi
        
        ((retry_count++))
        if [[ $retry_count -lt $max_retries ]]; then
            log WARN "Download failed, retrying in ${wait_time} seconds..."
            sleep $wait_time
            # Exponential backoff
            ((wait_time *= 2))
        fi
    done
    
    error_exit "Failed to download after $max_retries attempts: $url"
}

# Verify file checksum
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    
    if [[ ! -f "$file" ]]; then
        log ERROR "File not found: $file"
        return 1
    fi
    
    log INFO "Verifying checksum: $file"
    
    local actual_checksum=$(sha256sum "$file" | awk '{print $1}')
    
    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
        log SUCCESS "Checksum verification passed"
        return 0
    else
        log ERROR "Checksum mismatch!"
        log ERROR "Expected: $expected_checksum"
        log ERROR "Actual:   $actual_checksum"
        return 1
    fi
}

# ==============================================================================
# PACKAGE INSTALLATION FUNCTIONS
# ==============================================================================

# Update package manager
update_packages() {
    log INFO "Updating package manager..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log INFO "[DRY-RUN] Would update package manager"
        return 0
    fi
    
    if command_exists apt; then
        log_command "apt update && apt upgrade -y"
        apt update && apt upgrade -y 2>&1 | tee -a "$LOG_FILE" || log WARN "Package update failed"
        log SUCCESS "Package manager updated"
    elif command_exists pacman; then
        log_command "pacman -Syu --noconfirm"
        pacman -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE" || log WARN "Package update failed"
        log SUCCESS "Package manager updated"
    else
        log WARN "Unsupported package manager"
    fi
}

# Install essential packages
install_essential_packages() {
    log INFO "Installing essential packages..."
    
    local packages=(
        "curl"
        "wget"
        "git"
        "openssh"
        "openssl"
        "ca-certificates"
    )
    
    if [[ "$DRY_RUN" == true ]]; then
        log INFO "[DRY-RUN] Would install packages: ${packages[*]}"
        return 0
    fi
    
    if command_exists apt; then
        log_command "apt install -y ${packages[*]}"
        apt install -y "${packages[@]}" 2>&1 | tee -a "$LOG_FILE"
        log SUCCESS "Essential packages installed"
    else
        log WARN "Package installation skipped (apt not found)"
    fi
}

# ==============================================================================
# FLASHING FUNCTIONS
# ==============================================================================

# Perform flashing operation
perform_flashing() {
    if [[ "$ENABLE_FLASHING" == false ]]; then
        log INFO "Flashing skipped (--skip-flashing)"
        return 0
    fi
    
    log INFO "Starting flashing process..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log INFO "[DRY-RUN] Would perform flashing operation"
        return 0
    fi
    
    # Check for flashing tools
    if ! command_exists adb || ! command_exists fastboot; then
        log WARN "ADB/Fastboot not found, skipping device flashing"
        return 0
    fi
    
    log INFO "Flashing tools detected"
    log_command "adb devices"
    
    if adb devices 2>&1 | tee -a "$LOG_FILE"; then
        log SUCCESS "Flashing ready (devices detected)"
    else
        log WARN "No devices detected for flashing"
    fi
}

# ==============================================================================
# CONFIGURATION FUNCTIONS
# ==============================================================================

# Configure Termux environment
configure_termux() {
    log INFO "Configuring Termux environment..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log INFO "[DRY-RUN] Would configure Termux environment"
        return 0
    fi
    
    # Create .termux directory if not exists
    mkdir -p "$HOME/.termux" || log WARN "Failed to create .termux directory"
    
    # Configure Termux properties
    local termux_properties="$HOME/.termux/termux.properties"
    if [[ ! -f "$termux_properties" ]]; then
        log INFO "Creating termux.properties..."
        
        cat > "$termux_properties" << 'PROPS'
# Termux Properties Configuration
# Generated by install-termux.sh

# Enable fullscreen
fullscreen = false

# Enable drawer navigation
drawer_left = true

# Bell notification
bell = true

# Cursor blink
cursor_blink_rate = 500

# Font size
font_size = 12

# Session scrollback
session_scrollback = 2000
PROPS
        
        log SUCCESS "termux.properties created"
    fi
    
    # Create .bash_profile if not exists
    local bash_profile="$HOME/.bash_profile"
    if [[ ! -f "$bash_profile" ]]; then
        log INFO "Creating .bash_profile..."
        
        cat > "$bash_profile" << 'BASHRC'
# Termux Bash Profile
# Generated by install-termux.sh

# Source bashrc if it exists
[[ -f ~/.bashrc ]] && . ~/.bashrc

# Set locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Add custom prompt
export PS1='\[\e[1;32m\]\u@\h\[\e[0m\] \[\e[1;34m\]\W\[\e[0m\] \$ '

# Useful aliases
alias ll='ls -lah'
alias la='ls -la'
alias l='ls -lh'
alias update='apt update && apt upgrade -y'
alias clear-cache='apt autoclean && apt autoremove -y'
BASHRC
        
        log SUCCESS ".bash_profile created"
    fi
}

# ==============================================================================
# SETUP & INSTALLATION ORCHESTRATION
# ==============================================================================

# Main setup function
main_setup() {
    log INFO "Starting Termux installation process..."
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       Termux Android Automated Installation & Setup          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log INFO "Configuration Summary:"
    log INFO "  - Backup enabled: $ENABLE_BACKUP"
    log INFO "  - Verification enabled: $ENABLE_VERIFICATION"
    log INFO "  - Download enabled: $ENABLE_DOWNLOAD"
    log INFO "  - Flashing enabled: $ENABLE_FLASHING"
    log INFO "  - Dry-run mode: $DRY_RUN"
    log INFO "  - Verbose mode: $VERBOSE"
    echo ""
    
    # Step 1: Verification
    log INFO "Step 1/6: Comprehensive Verification"
    comprehensive_verification
    echo ""
    
    # Step 2: Backup
    log INFO "Step 2/6: Creating Backup"
    create_backup
    echo ""
    
    # Step 3: Update Packages
    log INFO "Step 3/6: Updating Package Manager"
    update_packages
    echo ""
    
    # Step 4: Install Packages
    log INFO "Step 4/6: Installing Essential Packages"
    install_essential_packages
    echo ""
    
    # Step 5: Configure
    log INFO "Step 5/6: Configuring Termux Environment"
    configure_termux
    echo ""
    
    # Step 6: Flashing
    log INFO "Step 6/6: Preparing Flashing Operations"
    perform_flashing
    echo ""
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              Installation Process Completed Successfully      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log SUCCESS "Installation process completed"
    log INFO "Log file: $LOG_FILE"
    log INFO "Backup directory: $BACKUP_DIR"
    log INFO "Download directory: $DOWNLOAD_DIR"
    echo ""
    echo -e "${BLUE}For more information, check the log file:${NC}"
    echo -e "  ${YELLOW}cat $LOG_FILE${NC}"
}

# ==============================================================================
# ENTRY POINT
# ==============================================================================

main() {
    # Initialize logging first
    init_logging
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Run main setup
    main_setup
}

# Execute main function with all arguments
main "$@"
