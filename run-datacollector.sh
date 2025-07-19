#!/bin/bash

# Script to run data collectors (Zeek, Argus, nfpcapd) based on configuration

# Color definitions for terminal output
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

# Configuration variables - set defaults and allow override
# Set to "true" to enable, any other value to disable
ENABLE_ARGUS="false"
ENABLE_ZEEK="false"
ENABLE_NFPCAPD="false"

# Default interface is eth0, can be overridden
ARGUS_INTERFACE="eth0"
NFPCAPD_INTERFACE="eth0"

# Default output directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARGUS_OUTPUTDIR="${SCRIPT_DIR}/log/argus"
NFPCAPD_OUTPUTDIR="${SCRIPT_DIR}/log/nfpcapd"

# Check if configuration file exists and load it
CONFIG_FILE="${SCRIPT_DIR}/enabled-datacollector.txt"
if [ -f "$CONFIG_FILE" ]; then
    print_info "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
fi

# Create output directories if they don't exist
mkdir -p "$ARGUS_OUTPUTDIR"
mkdir -p "$NFPCAPD_OUTPUTDIR"

print_info "Starting data collectors..."

# Run Argus if enabled
if [ "$ENABLE_ARGUS" = "true" ]; then
    print_info "Starting Argus on interface $ARGUS_INTERFACE..."
    
    # Create cron job for log rotation if it doesn't exist
    # CRON_JOB="0 0 * * * find $ARGUS_OUTPUTDIR -name 'output.argus' -exec sh -c 'FILENAME={}; mv \$FILENAME \$FILENAME.\$(date -d "yesterday" +%Y%m%d); gzip \$FILENAME.\$(date -d "yesterday" +%Y%m%d)' \;"
    CRON_JOB="0 0 * * * find $ARGUS_OUTPUTDIR -name 'output.argus' -exec sh -c 'FILENAME={}; mv \$FILENAME \$FILENAME.\$(date -d \"yesterday\" +%Y%m%d); gzip \$FILENAME.\$(date -d \"yesterday\" +%Y%m%d)' \;"

    
    if ! (crontab -l | grep -q "$ARGUS_OUTPUTDIR"); then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        print_info "Created log rotation for Argus"
    fi
    
    # Run Argus in background
    argus -i "$ARGUS_INTERFACE" -w "$ARGUS_OUTPUTDIR/output.argus" -d &
    if [ $? -eq 0 ]; then
        print_success "Argus started successfully"
    else
        print_error "Failed to start Argus"
    fi
else
    print_warning "Argus is disabled, skipping..."
fi

# Run nfpcapd if enabled
if [ "$ENABLE_NFPCAPD" = "true" ]; then
    print_info "Starting nfpcapd on interface $NFPCAPD_INTERFACE..."
    
    # Run nfpcapd
    nfpcapd -i "$NFPCAPD_INTERFACE" -j -D -l "$NFPCAPD_OUTPUTDIR/" -S 1 &
    if [ $? -eq 0 ]; then
        print_success "nfpcapd started successfully"
    else
        print_error "Failed to start nfpcapd"
    fi
else
    print_warning "nfpcapd is disabled, skipping..."
fi

# Run Zeek if enabled
if [ "$ENABLE_ZEEK" = "true" ]; then
    print_info "Starting Zeek..."
    
    # Deploy Zeek
    /opt/zeek/bin/zeekctl deploy
    if [ $? -eq 0 ]; then
        print_success "Zeek started successfully"
    else
        print_error "Failed to start Zeek"
    fi
else
    print_warning "Zeek is disabled, skipping..."
fi

print_info "Data collector startup complete"
