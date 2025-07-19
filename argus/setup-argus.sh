#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Directory where repositories will be cloned
REPO_OUTPUT_DIR="/opt"

# Argus environment variables
ARGUS_OUTPUT_FILE="/var/log/argus/argus.out"
ARGUS_OUTPUT_DIR="/var/log/argus"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_dependencies() {
    print_message "$BLUE" "Checking and installing required dependencies..."

    # Update package list
    print_message "$YELLOW" "Updating package list..."
    sudo apt-get update

    # Install build-essential
    if ! dpkg -l | grep -q build-essential; then
        print_message "$YELLOW" "Installing build-essential..."
        sudo apt-get install -y build-essential
    else
        print_message "$GREEN" "✓ build-essential is already installed"
    fi

    # Check and install tcpdump
    if ! command_exists tcpdump; then
        print_message "$YELLOW" "Installing tcpdump..."
        sudo apt-get install -y tcpdump
    else
        print_message "$GREEN" "✓ tcpdump is already installed"
    fi

    # Check and install bison and flex
    if ! command_exists bison || ! command_exists flex; then
        print_message "$YELLOW" "Installing bison and flex..."
        sudo apt-get install -y bison flex
    else
        print_message "$GREEN" "✓ bison and flex are already installed"
    fi

    # Install other required dependencies
    print_message "$YELLOW" "Installing additional required libraries..."
    sudo apt-get install -y libpcap0.8 libpcap0.8-dev libwrap0-dev

    print_message "$GREEN" "✓ All dependencies installed successfully"
}

# Function to setup environment variables
setup_environment() {
    print_message "$BLUE" "Setting up Argus environment variables..."
    
    # Create argus log directory
    sudo mkdir -p $ARGUS_OUTPUT_DIR
    
    # Add environment variables to ~/.bashrc if they don't exist
    if ! grep -q "ARGUS_OUTPUT_FILE=" ~/.bashrc; then
        print_message "$YELLOW" "Adding ARGUS_OUTPUT_FILE to ~/.bashrc"
        echo "export ARGUS_OUTPUT_FILE=$ARGUS_OUTPUT_FILE" >> ~/.bashrc
    fi
    
    if ! grep -q "ARGUS_OUTPUT_DIR=" ~/.bashrc; then
        print_message "$YELLOW" "Adding ARGUS_OUTPUT_DIR to ~/.bashrc"
        echo "export ARGUS_OUTPUT_DIR=$ARGUS_OUTPUT_DIR" >> ~/.bashrc
    fi
    
    # Set proper permissions for the log directory
    sudo chown -R $(whoami):$(whoami) $ARGUS_OUTPUT_DIR
    
    print_message "$GREEN" "✓ Environment variables have been set up"
    print_message "$YELLOW" "Please run 'source ~/.bashrc' after the installation to apply the changes"
    source ~/.bashrc
    print_message "$GREEN" "✓ Environment variables sourced successfully"
}

# Function to install an Argus component
install_argus_component() {
    local repo_url=$1
    local repo_name=$(basename $repo_url .git)
    
    print_message "$BLUE" "Installing $repo_name..."
    
    # Clone repository if it doesn't exist
    if [ ! -d "$REPO_OUTPUT_DIR/$repo_name" ]; then
        print_message "$YELLOW" "Cloning $repo_name..."
        sudo git clone $repo_url "$REPO_OUTPUT_DIR/$repo_name"
    else
        print_message "$YELLOW" "$repo_name directory already exists"
    fi
    
    # Enter repository directory
    cd "$REPO_OUTPUT_DIR/$repo_name"
    
    # Run installation commands
    print_message "$BLUE" "Configuring $repo_name..."
    sudo ./configure
    
    print_message "$BLUE" "Building $repo_name..."
    sudo make
    
    print_message "$BLUE" "Installing $repo_name..."
    sudo make install
    
    print_message "$GREEN" "✓ $repo_name installation completed"
}

# Main script
print_message "$BLUE" "Starting Argus installation..."

# Install dependencies first
install_dependencies

# Install Argus Server
install_argus_component "https://github.com/openargus/argus.git"

# Install Argus Client
install_argus_component "https://github.com/openargus/clients.git"

# Setup environment variables
setup_environment

print_message "$GREEN" "✓ Argus installation completed successfully!"
