#!/bin/bash

################################################################################
# Realme C63 - Common Functions Library
# Version: 1.0.0
# Description: Shared utility functions for all scripts
################################################################################

# Color Codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# ============================================================================
# Logging Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $*" >> "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARNING] $*" >> "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    [[ -n "${LOG_FILE:-}" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $*" >> "${LOG_FILE}"
}

log_debug() {
    if [[ "${DEBUG:-false}" == true ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*"
        [[ -n "${LOG_FILE:-}" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DEBUG] $*" >> "${LOG_FILE}"
    fi
}

# ============================================================================
# User Interaction Functions
# ============================================================================

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local response
    
    if [[ "${default}" == "y" ]]; then
        prompt="${prompt} [Y/n]: "
    else
        prompt="${prompt} [y/N]: "
    fi
    
    read -r -p "${prompt}" response
    response="${response:-${default}}"
    
    case "${response,,}" in
        y|yes) return 0 ;;
        n|no) return 1 ;;
        *) 
            log_warning "Invalid response. Please answer yes or no."
            prompt_yes_no "$1" "$2"
            ;;
    esac
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local value
    
    if [[ -n "${default}" ]]; then
        prompt="${prompt} [${default}]: "
    else
        prompt="${prompt}: "
    fi
    
    read -r -p "${prompt}" value
    echo "${value:-${default}}"
}

# ============================================================================
# File Operations
# ============================================================================

check_file_exists() {
    local file="$1"
    if [[ -f "${file}" ]]; then
        return 0
    else
        return 1
    fi
}

check_dir_exists() {
    local dir="$1"
    if [[ -d "${dir}" ]]; then
        return 0
    else
        return 1
    fi
}

create_directory() {
    local dir="$1"
    if [[ ! -d "${dir}" ]]; then
        mkdir -p "${dir}"
        log_debug "Created directory: ${dir}"
    fi
}

backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%s)"
    
    if [[ -f "${file}" ]]; then
        cp "${file}" "${backup}"
        log_info "Backup created: ${backup}"
        echo "${backup}"
    fi
}

# ============================================================================
# Command Checks
# ============================================================================

check_command() {
    local cmd="$1"
    if command -v "${cmd}" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

require_command() {
    local cmd="$1"
    if ! check_command "${cmd}"; then
        log_error "Required command not found: ${cmd}"
        return 1
    fi
    return 0
}

# ============================================================================
# System Checks
# ============================================================================

check_root() {
    if [[ "${EUID}" -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

require_root() {
    if ! check_root; then
        log_error "This script must be run as root"
        exit 1
    fi
}

get_os_type() {
    case "$(uname -s)" in
        Linux*)     echo "Linux" ;;
        Darwin*)    echo "macOS" ;;
        CYGWIN*)    echo "Windows" ;;
        MINGW*)     echo "Windows" ;;
        *)          echo "Unknown" ;;
    esac
}

get_arch() {
    uname -m
}

# ============================================================================
# String Functions
# ============================================================================

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

uppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# ============================================================================
# Progress Display
# ============================================================================

show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing}"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}%s${NC} [" "${message}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] %d%%" "${percent}"
}

show_spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local spinstr='|/-\'
    local i=0
    
    while kill -0 "${pid}" 2>/dev/null; do
        local temp=${spinstr:i++:1}
        printf "\r${CYAN}%s${NC} %c" "${message}" "${temp}"
        sleep 0.1
        if [[ ${i} -ge ${#spinstr} ]]; then
            i=0
        fi
    done
    printf "\r%${#message}s\r" " "
}

# ============================================================================
# Validation Functions
# ============================================================================

validate_ip() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ "${ip}" =~ ${regex} ]]; then
        return 0
    else
        return 1
    fi
}

validate_url() {
    local url="$1"
    local regex='^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$'
    
    if [[ "${url}" =~ ${regex} ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Cleanup Functions
# ============================================================================

cleanup_temp_files() {
    local temp_dir="${1:-./temp}"
    if [[ -d "${temp_dir}" ]]; then
        log_info "Cleaning up temporary files..."
        rm -rf "${temp_dir}"/*
        log_success "Cleanup completed"
    fi
}

# ============================================================================
# Error Handling
# ============================================================================

error_exit() {
    log_error "$1"
    exit "${2:-1}"
}

trap_errors() {
    local line_number="$1"
    local command="$2"
    log_error "Error at line ${line_number}: ${command}"
}

# Set error trap
trap 'trap_errors ${LINENO} "${BASH_COMMAND}"' ERR

# ============================================================================
# Export Functions (if needed by other scripts)
# ============================================================================

export -f log_info log_success log_warning log_error log_debug
export -f prompt_yes_no prompt_input
export -f check_file_exists check_dir_exists create_directory backup_file
export -f check_command require_command
export -f check_root require_root get_os_type get_arch
export -f trim lowercase uppercase
export -f show_progress show_spinner
export -f validate_ip validate_url
export -f cleanup_temp_files error_exit
