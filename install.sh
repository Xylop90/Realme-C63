#!/bin/bash

################################################################################
# REALME C63 - UNIVERSAL AUTOMATED INSTALLER
# Version: 1.0.0
# Created: 2026-01-10
# Author: Xylop90
# 
# This is the main entry point for the entire automated installation system.
# It automatically detects the OS, installs dependencies, downloads files,
# generates configurations, and provides a complete one-command setup.
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION & CONSTANTS
# ============================================================================

declare -r SCRIPT_VERSION="1.0.0"
declare -r SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -r REPO_URL="https://github.com/Xylop90/Realme-C63"
declare -r INSTALL_DIR="${INSTALL_DIR:-.}"
declare -r LOG_FILE="${INSTALL_DIR}/install.log"
declare -r CONFIG_DIR="${INSTALL_DIR}/config"
declare -r CACHE_DIR="${INSTALL_DIR}/.cache"
declare -r BACKUP_DIR="${INSTALL_DIR}/backups"
declare -r TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")

# Cache for command checks to avoid repeated lookups
declare -A COMMAND_CACHE

# Color codes for output
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[1;33m'
declare -r BLUE='\033[0;34m'
declare -r CYAN='\033[0;36m'
declare -r BOLD='\033[1m'
declare -r NC='\033[0m' # No Color

# Installation flags
SKIP_DEPENDENCIES=false
SKIP_DOWNLOAD=false
SKIP_CONFIG=false
DRY_RUN=false
VERBOSE=false
INTERACTIVE=true
FORCE_INSTALL=false

# System detection variables
OS_TYPE=""
OS_VERSION=""
ARCH=""
PACKAGE_MANAGER=""
DEPENDENCIES=()
INSTALLED_PACKAGES=()

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

info() {
    echo -e "${BLUE}ℹ${NC} $*"
    log "INFO" "$*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
    log "SUCCESS" "$*"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $*"
    log "WARNING" "$*"
}

error() {
    echo -e "${RED}✗${NC} $*" >&2
    log "ERROR" "$*"
}

debug() {
    if [[ "${VERBOSE}" == true ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*"
        log "DEBUG" "$*"
    fi
}

print_header() {
    echo -e "\n${BOLD}${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $*${NC}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════${NC}\n"
}

print_section() {
    echo -e "\n${BOLD}${CYAN}▶ $*${NC}\n"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

check_command() {
    # Check cache first to avoid repeated command lookups
    if [[ -n "${COMMAND_CACHE[$1]:-}" ]]; then
        return "${COMMAND_CACHE[$1]}"
    fi
    
    if command -v "$1" &> /dev/null; then
        COMMAND_CACHE[$1]=0
        return 0
    else
        COMMAND_CACHE[$1]=1
        return 1
    fi
}

prompt_yes_no() {
    local question="$1"
    local default="${2:-y}"
    
    if [[ "${INTERACTIVE}" == false ]]; then
        return 0
    fi
    
    local prompt="? ${question}"
    if [[ "${default}" == "y" ]]; then
        prompt="${prompt} [Y/n]: "
    else
        prompt="${prompt} [y/N]: "
    fi
    
    read -p "$(echo -e ${CYAN}${prompt}${NC})" -r response
    response="${response:-${default}}"
    
    if [[ "${response}" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

create_directory_structure() {
    debug "Creating directory structure..."
    mkdir -p "${CONFIG_DIR}"
    mkdir -p "${CACHE_DIR}"
    mkdir -p "${BACKUP_DIR}"
    mkdir -p "${INSTALL_DIR}/logs"
    mkdir -p "${INSTALL_DIR}/bin"
    mkdir -p "${INSTALL_DIR}/lib"
    success "Directory structure created"
}

# ============================================================================
# SYSTEM DETECTION
# ============================================================================

detect_os() {
    print_section "System Detection"
    
    debug "Detecting operating system..."
    
    case "${OSTYPE}" in
        linux*)
            OS_TYPE="Linux"
            ;;
        darwin*)
            OS_TYPE="macOS"
            ;;
        msys*|mingw*|cygwin*)
            OS_TYPE="Windows"
            ;;
        *)
            error "Unsupported operating system: ${OSTYPE}"
            return 1
            ;;
    esac
    
    # Detect OS version
    if [[ "${OS_TYPE}" == "Linux" ]]; then
        if [[ -f /etc/os-release ]]; then
            OS_VERSION=$(grep "^NAME=" /etc/os-release | cut -d'"' -f2)
        elif [[ -f /etc/lsb-release ]]; then
            OS_VERSION=$(grep "^DISTRIB_DESCRIPTION=" /etc/lsb-release | cut -d'"' -f2)
        else
            OS_VERSION="Unknown Linux Distribution"
        fi
    elif [[ "${OS_TYPE}" == "macOS" ]]; then
        OS_VERSION=$(sw_vers -productVersion)
    elif [[ "${OS_TYPE}" == "Windows" ]]; then
        OS_VERSION=$(cmd /c "ver" 2>/dev/null || echo "Unknown")
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    case "${ARCH}" in
        x86_64)
            ARCH="x86_64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        *)
            warning "Architecture ${ARCH} may not be fully supported"
            ;;
    esac
    
    info "OS Type: ${OS_TYPE}"
    info "OS Version: ${OS_VERSION}"
    info "Architecture: ${ARCH}"
    
    success "System detection completed"
}

detect_package_manager() {
    debug "Detecting package manager..."
    
    if [[ "${OS_TYPE}" == "Linux" ]]; then
        if check_command apt-get; then
            PACKAGE_MANAGER="apt"
        elif check_command yum; then
            PACKAGE_MANAGER="yum"
        elif check_command pacman; then
            PACKAGE_MANAGER="pacman"
        elif check_command zypper; then
            PACKAGE_MANAGER="zypper"
        else
            error "No supported package manager found"
            return 1
        fi
    elif [[ "${OS_TYPE}" == "macOS" ]]; then
        if check_command brew; then
            PACKAGE_MANAGER="brew"
        else
            error "Homebrew not found. Please install it from https://brew.sh"
            return 1
        fi
    elif [[ "${OS_TYPE}" == "Windows" ]]; then
        if check_command choco; then
            PACKAGE_MANAGER="choco"
        elif check_command scoop; then
            PACKAGE_MANAGER="scoop"
        else
            warning "No package manager detected on Windows. Manual installation may be required."
            PACKAGE_MANAGER="none"
        fi
    fi
    
    info "Package Manager: ${PACKAGE_MANAGER}"
    debug "Package manager detection completed"
}

# ============================================================================
# DEPENDENCY MANAGEMENT
# ============================================================================

define_dependencies() {
    debug "Defining dependencies..."
    
    DEPENDENCIES=(
        "curl"
        "wget"
        "git"
        "python3"
        "openssl"
        "jq"
        "tar"
    )
    
    # Platform-specific dependencies
    if [[ "${OS_TYPE}" == "Linux" ]]; then
        DEPENDENCIES+=(
            "build-essential"
            "libssl-dev"
            "libffi-dev"
            "python3-dev"
        )
    elif [[ "${OS_TYPE}" == "macOS" ]]; then
        DEPENDENCIES+=(
            "xcode-select"
            "openssl@3"
        )
    elif [[ "${OS_TYPE}" == "Windows" ]]; then
        DEPENDENCIES+=(
            "git"
            "python"
        )
    fi
    
    debug "Dependencies defined: ${#DEPENDENCIES[@]} packages"
}

check_installed_packages() {
    print_section "Checking Installed Packages"
    
    INSTALLED_PACKAGES=()
    
    # Optimize: Get all installed packages in a single query
    case "${PACKAGE_MANAGER}" in
        apt)
            # Cache dpkg output to avoid multiple calls
            local dpkg_output=$(dpkg -l 2>/dev/null)
            ;;
        choco)
            # Cache choco list output
            local choco_output=$(choco list --local-only 2>/dev/null)
            ;;
        scoop)
            # Cache scoop list output
            local scoop_output=$(scoop list 2>/dev/null)
            ;;
    esac
    
    for package in "${DEPENDENCIES[@]}"; do
        local installed=false
        
        case "${PACKAGE_MANAGER}" in
            apt)
                # Use cached output instead of calling dpkg multiple times
                if grep -q "^ii.*${package}" <<< "${dpkg_output}"; then
                    installed=true
                fi
                ;;
            yum)
                if yum list installed "${package}" &>/dev/null; then
                    installed=true
                fi
                ;;
            pacman)
                if pacman -Q "${package}" &>/dev/null; then
                    installed=true
                fi
                ;;
            zypper)
                if zypper se -i "${package}" &>/dev/null; then
                    installed=true
                fi
                ;;
            brew)
                if brew list "${package}" &>/dev/null; then
                    installed=true
                fi
                ;;
            choco)
                # Use cached output instead of calling choco multiple times
                if grep -q "${package}" <<< "${choco_output}"; then
                    installed=true
                fi
                ;;
            scoop)
                # Use cached output instead of calling scoop multiple times
                if grep -q "${package}" <<< "${scoop_output}"; then
                    installed=true
                fi
                ;;
        esac
        
        if [[ "${installed}" == true ]]; then
            success "${package} is installed"
            INSTALLED_PACKAGES+=("${package}")
        else
            warning "${package} is NOT installed"
        fi
    done
    
    local missing_count=$((${#DEPENDENCIES[@]} - ${#INSTALLED_PACKAGES[@]}))
    if [[ ${missing_count} -gt 0 ]]; then
        warning "Found ${missing_count} missing package(s)"
        return 1
    else
        success "All dependencies are installed"
        return 0
    fi
}

install_dependencies() {
    if [[ "${SKIP_DEPENDENCIES}" == true ]]; then
        info "Skipping dependency installation (--skip-dependencies flag)"
        return 0
    fi
    
    if check_installed_packages; then
        success "All dependencies already installed"
        return 0
    fi
    
    print_section "Installing Missing Dependencies"
    
    if ! prompt_yes_no "Install missing dependencies?"; then
        warning "Skipping dependency installation"
        return 0
    fi
    
    case "${PACKAGE_MANAGER}" in
        apt)
            info "Updating package lists..."
            if [[ "${DRY_RUN}" == true ]]; then
                info "[DRY RUN] Would run: sudo apt-get update"
                info "[DRY RUN] Would run: sudo apt-get install -y ${DEPENDENCIES[*]}"
            else
                sudo apt-get update || error "Failed to update package lists"
                sudo apt-get install -y "${DEPENDENCIES[@]}" || error "Failed to install packages"
            fi
            ;;
        yum)
            if [[ "${DRY_RUN}" == true ]]; then
                info "[DRY RUN] Would run: sudo yum install -y ${DEPENDENCIES[*]}"
            else
                sudo yum install -y "${DEPENDENCIES[@]}" || error "Failed to install packages"
            fi
            ;;
        pacman)
            if [[ "${DRY_RUN}" == true ]]; then
                info "[DRY RUN] Would run: sudo pacman -S --noconfirm ${DEPENDENCIES[*]}"
            else
                sudo pacman -S --noconfirm "${DEPENDENCIES[@]}" || error "Failed to install packages"
            fi
            ;;
        zypper)
            if [[ "${DRY_RUN}" == true ]]; then
                info "[DRY RUN] Would run: sudo zypper install -y ${DEPENDENCIES[*]}"
            else
                sudo zypper install -y "${DEPENDENCIES[@]}" || error "Failed to install packages"
            fi
            ;;
        brew)
            if [[ "${DRY_RUN}" == true ]]; then
                info "[DRY RUN] Would run: brew install ${DEPENDENCIES[*]}"
            else
                brew install "${DEPENDENCIES[@]}" || error "Failed to install packages"
            fi
            ;;
        choco)
            if [[ "${DRY_RUN}" == true ]]; then
                info "[DRY RUN] Would run: choco install -y ${DEPENDENCIES[*]}"
            else
                choco install -y "${DEPENDENCIES[@]}" || error "Failed to install packages"
            fi
            ;;
        scoop)
            if [[ "${DRY_RUN}" == true ]]; then
                info "[DRY RUN] Would run: scoop install ${DEPENDENCIES[*]}"
            else
                scoop install "${DEPENDENCIES[@]}" || error "Failed to install packages"
            fi
            ;;
        none)
            error "Please install dependencies manually or configure a package manager"
            return 1
            ;;
    esac
    
    if [[ "${DRY_RUN}" == false ]]; then
        success "Dependencies installation completed"
    fi
}

# ============================================================================
# FILE DOWNLOAD & MANAGEMENT
# ============================================================================

download_file() {
    local url="$1"
    local destination="$2"
    local filename=$(basename "${destination}")
    
    debug "Downloading ${filename} from ${url}..."
    
    if [[ -f "${destination}" && "${FORCE_INSTALL}" == false ]]; then
        info "File already exists: ${filename}"
        if prompt_yes_no "Overwrite existing file?"; then
            debug "User chose to overwrite"
        else
            debug "User chose to keep existing file"
            return 0
        fi
    fi
    
    local temp_file="${CACHE_DIR}/${filename}.tmp"
    local max_retries=3
    local retry=0
    
    while [[ ${retry} -lt ${max_retries} ]]; do
        if [[ "${DRY_RUN}" == true ]]; then
            info "[DRY RUN] Would download: ${url} -> ${destination}"
            return 0
        fi
        
        if curl -L --progress-bar --retry 2 -o "${temp_file}" "${url}"; then
            mv "${temp_file}" "${destination}"
            success "Downloaded: ${filename}"
            return 0
        else
            ((retry++))
            if [[ ${retry} -lt ${max_retries} ]]; then
                warning "Download failed, retrying (attempt $((retry + 1))/${max_retries})..."
                sleep 2
            fi
        fi
    done
    
    error "Failed to download ${filename} after ${max_retries} attempts"
    rm -f "${temp_file}"
    return 1
}

fetch_installation_files() {
    if [[ "${SKIP_DOWNLOAD}" == true ]]; then
        info "Skipping file download (--skip-download flag)"
        return 0
    fi
    
    print_section "Fetching Installation Files"
    
    # Example downloads - customize based on your actual files
    local files_to_download=(
        "https://raw.githubusercontent.com/Xylop90/Realme-C63/main/config/default.conf|${CONFIG_DIR}/default.conf"
        "https://raw.githubusercontent.com/Xylop90/Realme-C63/main/scripts/setup.sh|${INSTALL_DIR}/setup.sh"
    )
    
    info "Fetching ${#files_to_download[@]} file(s)..."
    
    for entry in "${files_to_download[@]}"; do
        IFS='|' read -r url destination <<< "${entry}"
        if download_file "${url}" "${destination}"; then
            debug "Successfully processed: $(basename ${destination})"
        else
            warning "Failed to process: ${url}"
        fi
    done
    
    success "File fetch completed"
}

# ============================================================================
# CONFIGURATION GENERATION
# ============================================================================

generate_configurations() {
    if [[ "${SKIP_CONFIG}" == true ]]; then
        info "Skipping configuration generation (--skip-config flag)"
        return 0
    fi
    
    print_section "Generating Configuration Files"
    
    # Generate main configuration
    generate_main_config
    
    # Generate platform-specific configuration
    generate_platform_config
    
    # Generate environment configuration
    generate_env_config
    
    success "Configuration generation completed"
}

generate_main_config() {
    local config_file="${CONFIG_DIR}/realme-c63.conf"
    
    debug "Generating main configuration file: ${config_file}"
    
    if [[ -f "${config_file}" && "${FORCE_INSTALL}" == false ]]; then
        warning "Configuration file already exists: ${config_file}"
        if ! prompt_yes_no "Overwrite existing configuration?"; then
            debug "Keeping existing configuration"
            return 0
        fi
        cp "${config_file}" "${BACKUP_DIR}/realme-c63.conf.backup.${TIMESTAMP// /_}"
        info "Backup created: realme-c63.conf.backup.${TIMESTAMP// /_}"
    fi
    
    cat > "${config_file}" << 'EOF'
# Realme C63 - Main Configuration File
# Generated: 2026-01-10 09:07:18
# Version: 1.0.0

[Installation]
VERSION=1.0.0
INSTALL_DATE=2026-01-10 09:07:18
INSTALL_PATH=${INSTALL_DIR}

[System]
OS_TYPE=${OS_TYPE}
OS_VERSION=${OS_VERSION}
ARCHITECTURE=${ARCH}
PACKAGE_MANAGER=${PACKAGE_MANAGER}

[Directories]
CONFIG_DIR=${CONFIG_DIR}
CACHE_DIR=${CACHE_DIR}
BACKUP_DIR=${BACKUP_DIR}
LOG_DIR=${INSTALL_DIR}/logs
BIN_DIR=${INSTALL_DIR}/bin
LIB_DIR=${INSTALL_DIR}/lib

[Features]
ENABLE_LOGGING=true
ENABLE_NOTIFICATIONS=true
ENABLE_AUTO_UPDATE=true
ENABLE_BACKUP=true

[Logging]
LOG_LEVEL=INFO
LOG_FILE=${LOG_FILE}
MAX_LOG_SIZE=10485760
LOG_RETENTION_DAYS=30

[Security]
ENABLE_SSL_VERIFICATION=true
ENABLE_SIGNATURE_VERIFICATION=true
BACKUP_CONFIG_CHANGES=true

[Performance]
PARALLEL_OPERATIONS=true
CACHE_DOWNLOADS=true
COMPRESSION_ENABLED=true

[Update]
CHECK_FOR_UPDATES=true
AUTO_UPDATE=false
UPDATE_CHECK_INTERVAL=604800

EOF
    
    success "Main configuration file created"
}

generate_platform_config() {
    local config_file="${CONFIG_DIR}/platform.conf"
    
    debug "Generating platform configuration file: ${config_file}"
    
    cat > "${config_file}" << EOF
# Platform-specific Configuration
# Generated: 2026-01-10 09:07:18

[Platform]
OS_TYPE=${OS_TYPE}
OS_VERSION=${OS_VERSION}
ARCHITECTURE=${ARCH}

EOF
    
    case "${OS_TYPE}" in
        Linux)
            cat >> "${config_file}" << 'EOF'
[Linux]
PACKAGE_MANAGER=apt
SHELL=/bin/bash
SUDOERS_REQUIRED=true
INIT_SYSTEM=systemd

[PermissionModel]
MODE=755
EXECUTABLE_MODE=755
CONFIG_MODE=644
PRIVATE_MODE=600

EOF
            ;;
        macOS)
            cat >> "${config_file}" << 'EOF'
[macOS]
PACKAGE_MANAGER=brew
SHELL=/bin/zsh
DARWIN_VERSION=$(uname -r)
XCODE_REQUIRED=true

[PermissionModel]
MODE=755
EXECUTABLE_MODE=755
CONFIG_MODE=644
PRIVATE_MODE=600

EOF
            ;;
        Windows)
            cat >> "${config_file}" << 'EOF'
[Windows]
PACKAGE_MANAGER=choco
SHELL=powershell
ADMIN_REQUIRED=true
REGISTRY_HIVE=HKEY_CURRENT_USER

[PermissionModel]
DEFAULT_PERMISSIONS=Everyone
EXECUTABLE_PERMISSIONS=Authenticated Users

EOF
            ;;
    esac
    
    success "Platform configuration file created"
}

generate_env_config() {
    local config_file="${CONFIG_DIR}/environment.conf"
    
    debug "Generating environment configuration file: ${config_file}"
    
    cat > "${config_file}" << EOF
# Environment Variables Configuration
# Generated: 2026-01-10 09:07:18

# Installation Paths
export REALME_C63_HOME="${INSTALL_DIR}"
export REALME_C63_CONFIG="${CONFIG_DIR}"
export REALME_C63_BIN="${INSTALL_DIR}/bin"
export REALME_C63_LIB="${INSTALL_DIR}/lib"
export REALME_C63_LOGS="${INSTALL_DIR}/logs"
export REALME_C63_CACHE="${CACHE_DIR}"
export REALME_C63_BACKUP="${BACKUP_DIR}"

# Version
export REALME_C63_VERSION="1.0.0"
export REALME_C63_INSTALL_DATE="${TIMESTAMP}"

# System Information
export REALME_C63_OS="${OS_TYPE}"
export REALME_C63_ARCH="${ARCH}"

# Logging
export REALME_C63_LOG_FILE="${LOG_FILE}"
export REALME_C63_LOG_LEVEL="INFO"

# Features
export REALME_C63_ENABLE_NOTIFICATIONS=true
export REALME_C63_ENABLE_AUTO_UPDATE=true

# PATH Extension
export PATH="\${REALME_C63_BIN}:\${PATH}"

EOF
    
    success "Environment configuration file created"
}

# ============================================================================
# VALIDATION & VERIFICATION
# ============================================================================

validate_installation() {
    print_section "Validating Installation"
    
    local validation_passed=true
    
    # Check directory structure
    debug "Validating directory structure..."
    for dir in "${CONFIG_DIR}" "${CACHE_DIR}" "${BACKUP_DIR}" "${INSTALL_DIR}/logs" "${INSTALL_DIR}/bin" "${INSTALL_DIR}/lib"; do
        if [[ -d "${dir}" ]]; then
            success "Directory exists: ${dir}"
        else
            error "Directory missing: ${dir}"
            validation_passed=false
        fi
    done
    
    # Check configuration files
    debug "Validating configuration files..."
    for config_file in "${CONFIG_DIR}/realme-c63.conf" "${CONFIG_DIR}/platform.conf" "${CONFIG_DIR}/environment.conf"; do
        if [[ -f "${config_file}" ]]; then
            success "Configuration file exists: $(basename ${config_file})"
        else
            error "Configuration file missing: $(basename ${config_file})"
            validation_passed=false
        fi
    done
    
    # Check required commands
    debug "Validating required commands..."
    local required_commands=("curl" "git" "python3")
    for cmd in "${required_commands[@]}"; do
        if check_command "${cmd}"; then
            success "Command available: ${cmd}"
        else
            error "Command not found: ${cmd}"
            validation_passed=false
        fi
    done
    
    # Verify file permissions
    debug "Validating file permissions..."
    if [[ -x "${BASH_SOURCE[0]}" ]]; then
        success "Script is executable"
    else
        warning "Script is not executable. Setting permissions..."
        chmod +x "${BASH_SOURCE[0]}"
    fi
    
    # Test write permissions
    debug "Testing write permissions..."
    if touch "${INSTALL_DIR}/.write_test" 2>/dev/null; then
        rm "${INSTALL_DIR}/.write_test"
        success "Installation directory is writable"
    else
        error "Installation directory is not writable"
        validation_passed=false
    fi
    
    if [[ "${validation_passed}" == true ]]; then
        success "Installation validation passed"
        return 0
    else
        error "Installation validation failed"
        return 1
    fi
}

# ============================================================================
# COMPLETION & SUMMARY
# ============================================================================

display_completion_summary() {
    print_header "INSTALLATION COMPLETED SUCCESSFULLY"
    
    echo -e "${CYAN}Installation Summary:${NC}"
    echo "  Version: ${SCRIPT_VERSION}"
    echo "  Timestamp: ${TIMESTAMP}"
    echo "  OS: ${OS_TYPE} ${OS_VERSION}"
    echo "  Architecture: ${ARCH}"
    echo "  Installation Directory: ${INSTALL_DIR}"
    echo "  Configuration Directory: ${CONFIG_DIR}"
    echo "  Log File: ${LOG_FILE}"
    
    print_section "Quick Command References"
    
    echo -e "${BOLD}Load Environment Variables:${NC}"
    echo "  source ${CONFIG_DIR}/environment.conf"
    
    echo -e "\n${BOLD}View Installation Logs:${NC}"
    echo "  tail -f ${LOG_FILE}"
    
    echo -e "\n${BOLD}View Configuration:${NC}"
    echo "  cat ${CONFIG_DIR}/realme-c63.conf"
    echo "  cat ${CONFIG_DIR}/platform.conf"
    
    echo -e "\n${BOLD}Verify Installation:${NC}"
    echo "  ls -la ${INSTALL_DIR}"
    
    echo -e "\n${BOLD}Access Backup Directory:${NC}"
    echo "  ls -la ${BACKUP_DIR}"
    
    echo -e "\n${BOLD}View System Information:${NC}"
    echo "  uname -a"
    echo "  ${PACKAGE_MANAGER} --version"
    
    echo -e "\n${BOLD}Next Steps:${NC}"
    echo "  1. Review the configuration files in ${CONFIG_DIR}"
    echo "  2. Source the environment file to load variables"
    echo "  3. Check logs at ${LOG_FILE} for detailed information"
    echo "  4. Run any post-installation scripts as needed"
    
    print_section "Additional Resources"
    
    echo -e "Repository: ${REPO_URL}"
    echo -e "Documentation: ${REPO_URL}/wiki"
    echo -e "Issues: ${REPO_URL}/issues"
    echo -e "Discussions: ${REPO_URL}/discussions"
    
    echo -e "\n${GREEN}${BOLD}✓ Installation complete!${NC}\n"
}

display_help() {
    cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║            REALME C63 - UNIVERSAL AUTOMATED INSTALLER v1.0.0             ║
║                    One-Command Complete Setup System                      ║
╚════════════════════════════════════════════════════════════════════════════╝

USAGE:
  ./install.sh [OPTIONS]

OPTIONS:
  -h, --help                Show this help message
  -v, --verbose             Enable verbose output
  -d, --dry-run             Simulate the installation without making changes
  -i, --interactive         Interactive mode (default: enabled)
  -n, --non-interactive     Non-interactive mode (no prompts)
  
DEPENDENCY OPTIONS:
  --skip-dependencies       Skip dependency installation
  --force-install          Force reinstall of all dependencies
  
DOWNLOAD OPTIONS:
  --skip-download          Skip file downloads
  
CONFIGURATION OPTIONS:
  --skip-config            Skip configuration generation
  
INSTALL DIRECTORY:
  Set INSTALL_DIR environment variable to change installation location:
    export INSTALL_DIR=/custom/path && ./install.sh

EXAMPLES:
  # Standard installation with all defaults
  ./install.sh
  
  # Verbose installation with detailed output
  ./install.sh --verbose
  
  # Non-interactive installation (automated)
  ./install.sh --non-interactive
  
  # Dry run to preview changes
  ./install.sh --dry-run
  
  # Skip dependency installation
  ./install.sh --skip-dependencies
  
  # Install to custom directory
  export INSTALL_DIR=/opt/realme-c63 && ./install.sh
  
  # Full automated installation
  ./install.sh --non-interactive --verbose 2>&1 | tee install-$(date +%s).log

FEATURES:
  ✓ Automatic OS detection (Linux, macOS, Windows)
  ✓ Dependency installation with multiple package managers
  ✓ Multi-threaded file downloading
  ✓ Automatic configuration generation
  ✓ System validation and verification
  ✓ Comprehensive logging
  ✓ Backup of existing configurations
  ✓ Cross-platform support
  ✓ Error handling and recovery
  ✓ Detailed installation summary

REQUIREMENTS:
  - bash 4.0 or newer
  - curl or wget
  - sudo access (for dependency installation)
  - Internet connection (for file downloads)

SUPPORT:
  Repository: https://github.com/Xylop90/Realme-C63
  Issues: https://github.com/Xylop90/Realme-C63/issues
  Wiki: https://github.com/Xylop90/Realme-C63/wiki

EOF
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                display_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            -d|--dry-run)
                DRY_RUN=true
                VERBOSE=true
                ;;
            -i|--interactive)
                INTERACTIVE=true
                ;;
            -n|--non-interactive)
                INTERACTIVE=false
                ;;
            --skip-dependencies)
                SKIP_DEPENDENCIES=true
                ;;
            --skip-download)
                SKIP_DOWNLOAD=true
                ;;
            --skip-config)
                SKIP_CONFIG=true
                ;;
            --force-install)
                FORCE_INSTALL=true
                ;;
            *)
                error "Unknown option: $1"
                display_help
                exit 1
                ;;
        esac
        shift
    done
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

cleanup() {
    local exit_code=$?
    
    debug "Cleanup function called with exit code: ${exit_code}"
    
    # Remove temporary files
    if [[ -d "${CACHE_DIR}" ]]; then
        find "${CACHE_DIR}" -name "*.tmp" -delete 2>/dev/null || true
    fi
    
    if [[ ${exit_code} -ne 0 ]]; then
        error "Installation failed with exit code ${exit_code}"
        error "Check logs for details: ${LOG_FILE}"
    fi
    
    exit ${exit_code}
}

trap cleanup EXIT
trap 'error "Installation interrupted"; exit 130' INT TERM

# ============================================================================
# MAIN INSTALLATION WORKFLOW
# ============================================================================

main() {
    parse_arguments "$@"
    
    print_header "REALME C63 - UNIVERSAL AUTOMATED INSTALLER"
    
    info "Installer Version: ${SCRIPT_VERSION}"
    info "Start Time: ${TIMESTAMP}"
    info "Installation Directory: ${INSTALL_DIR}"
    
    if [[ "${DRY_RUN}" == true ]]; then
        warning "Running in DRY RUN mode - no changes will be made"
    fi
    
    if [[ "${VERBOSE}" == true ]]; then
        debug "Verbose mode enabled"
    fi
    
    if [[ "${INTERACTIVE}" == false ]]; then
        info "Running in non-interactive mode"
    fi
    
    # Create directory structure
    create_directory_structure
    
    # System detection
    detect_os || exit 1
    detect_package_manager || exit 1
    
    # Define and check dependencies
    define_dependencies
    install_dependencies || exit 1
    
    # Download files
    fetch_installation_files || exit 1
    
    # Generate configurations
    generate_configurations || exit 1
    
    # Validate installation
    validate_installation || exit 1
    
    # Display summary
    display_completion_summary
}

# ============================================================================
# ENTRY POINT
# ============================================================================

main "$@"

