#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print success message
print_success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print error message
print_error() {
    echo -e "${RED}$1${NC}"
}

# Function to print info message
print_info() {
    echo -e "${BLUE}$1${NC}"
}

# Function to print warning message
print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to check if a program can run
check_program_runnable() {
    local program=$1
    local command=$2
    
    echo "Checking if $program can run..."
    if eval "$command" > /dev/null 2>&1; then
        print_success "$program=ready"
        return 0
    else
        print_error "$program=not ready"
        return 1
    fi
}


# Check if programs can run
echo -e "\nChecking if data collectors can run..."
check_program_runnable "zeek" "/opt/zeek/bin/zeek -h"
# check_program_runnable "argus" "argus -h"
check_program_runnable "nfpcapd" "nfpcapd -h"

# Check Zeek configuration files
echo -e "\nChecking Zeek configuration files..."

# Check node.cfg for interface
echo "Checking /opt/zeek/etc/node.cfg..."
if [ -f "/opt/zeek/etc/node.cfg" ]; then
    interface=$(grep "interface=" /opt/zeek/etc/node.cfg | head -1 | cut -d'=' -f2)
    if [ -n "$interface" ]; then
        print_info "Zeek Capture Interface = $interface"
    else
        print_warning "No interface found in node.cfg"
    fi
else
    print_error "File /opt/zeek/etc/node.cfg not found"
fi

# Check zeekctl.cfg for LogDir
echo "Checking /opt/zeek/etc/zeekctl.cfg..."
if [ -f "/opt/zeek/etc/zeekctl.cfg" ]; then
    logdir=$(grep "LogDir =" /opt/zeek/etc/zeekctl.cfg | head -1 | cut -d'=' -f2 | tr -d ' ')
    if [ -n "$logdir" ]; then
        print_info "Zeek LogDir = $logdir"
    else
        print_warning "No LogDir found in zeekctl.cfg"
    fi
else
    print_error "File /opt/zeek/etc/zeekctl.cfg not found"
fi

# Check local.zeek for ignore_checksums
echo "Checking /opt/zeek/share/zeek/site/local.zeek..."
if [ -f "/opt/zeek/share/zeek/site/local.zeek" ]; then
    if grep -q "redef ignore_checksums=T" "/opt/zeek/share/zeek/site/local.zeek" && \
       grep -q "@load frameworks/files/extract-all-files" "/opt/zeek/share/zeek/site/local.zeek"; then
        print_success "Ignore Checksums is enabled"
    else
        print_error "Ignore Checksums is disabled"
    fi
else
    print_error "File /opt/zeek/share/zeek/site/local.zeek not found"
fi

echo -e "\nCheck completed."
