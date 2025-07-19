#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    print_message "$RED" "Please run this script with sudo or as root"
    exit 1
fi

# Check if gpg is installed
check_gpg() {
    print_message "$BLUE" "Checking if gpg is installed..."
    if ! command -v gpg &> /dev/null; then
        print_message "$YELLOW" "GPG is not installed. Installing it now..."
        apt-get update
        apt-get install -y gnupg
        
        # Verify installation
        if command -v gpg &> /dev/null; then
            print_message "$GREEN" "GPG has been successfully installed."
        else
            print_message "$RED" "Failed to install GPG. Please install it manually and run this script again."
            exit 1
        fi
    else
        print_message "$GREEN" "GPG is already installed."
    fi
}

# Check if zeek is already installed
check_zeek_installation() {
    print_message "$BLUE" "Checking if Zeek is already installed..."
    
    if command -v zeek &> /dev/null || [ -d "/opt/zeek" ]; then
        print_message "$YELLOW" "Zeek is already installed."
        read -p "Do you want to reinstall it? (y/n): " choice
        case "$choice" in
            y|Y )
                print_message "$BLUE" "Proceeding with reinstallation..."
                ;;
            * )
                print_message "$GREEN" "Exiting setup script."
                exit 0
                ;;
        esac
    else
        print_message "$GREEN" "Zeek is not installed. Proceeding with installation..."
    fi
}

# Get Ubuntu version
get_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        print_message "$BLUE" "Detected OS: $OS_NAME $OS_VERSION"
        
        if [[ $OS_NAME != *"Ubuntu"* ]]; then
            print_message "$RED" "This script is designed for Ubuntu. Your OS is $OS_NAME."
            exit 1
        fi
        
        return 0
    else
        print_message "$RED" "Cannot determine OS version. This script is designed for Ubuntu."
        exit 1
    fi
}

# Setup environment variables
setup_env_variables() {
    print_message "$BLUE" "Setting up environment variables..."
    
    # System-wide environment variables
    if ! grep -q "ZEEK_PATH=/opt/zeek" /etc/environment; then
        echo 'ZEEK_PATH=/opt/zeek' | sudo tee -a /etc/environment > /dev/null
        echo 'PATH=$PATH:$ZEEK_PATH/bin' | sudo tee -a /etc/environment > /dev/null
        
        print_message "$GREEN" "Environment variables added to /etc/environment for all users."
        print_message "$YELLOW" "Please log out and log back in for the changes to take effect."
        print_message "$YELLOW" "Alternatively, run: source /etc/environment"
    else
        print_message "$GREEN" "System-wide environment variables are already set up."
    fi
    
    # Setup for root user
    setup_user_env_vars "/root"
    
    # Setup for current user if not root
    if [ "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        USER_HOME=$(eval echo ~$SUDO_USER)
        setup_user_env_vars "$USER_HOME"
    fi
    
    # Add to current session
    export ZEEK_PATH=/opt/zeek
    export PATH=$PATH:$ZEEK_PATH/bin
}

# Helper function to setup env vars for a specific user
setup_user_env_vars() {
    local user_home=$1
    local shell_rc=""
    
    # Determine which shell configuration file to use
    if [ -f "$user_home/.zshrc" ]; then
        shell_rc="$user_home/.zshrc"
    elif [ -f "$user_home/.bashrc" ]; then
        shell_rc="$user_home/.bashrc"
    else
        # Default to .bashrc if no other exists
        shell_rc="$user_home/.bashrc"
        touch "$shell_rc"
    fi
    
    print_message "$BLUE" "Setting up environment variables in $shell_rc"
    
    # Check if variables already exist in shell configuration
    if ! grep -q "ZEEK_PATH=/opt/zeek" "$shell_rc"; then
        # Add to shell configuration with comment
        echo -e "\n# Zeek environment variables" >> "$shell_rc"
        echo 'export ZEEK_PATH=/opt/zeek' >> "$shell_rc"
        echo 'export ZEEK_PATH=/opt/zeek' >> "/etc/bash.bashrc"
        echo 'export PATH=$PATH:ZEEK_PATH/bin' >> "/etc/bash.bashrc"
        echo 'export PATH=$PATH:$ZEEK_PATH/bin' >> "$shell_rc"
        
        # Fix permissions if modifying another user's file
        if [ "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
            chown $SUDO_USER:$(id -gn $SUDO_USER) "$shell_rc"
        fi
        
        print_message "$GREEN" "Environment variables added to $shell_rc"
    else
        print_message "$GREEN" "Environment variables already exist in $shell_rc"
    fi
}

# Install Zeek based on Ubuntu version
install_zeek() {
    local version=$1
    
    print_message "$BLUE" "Installing Zeek for Ubuntu $version..."
    
    case $version in
        "25.04")
            echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_25.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
            curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_25.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
            ;;
        "24.10")
            echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_24.10/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
            curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_24.10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
            ;;
        "24.04")
            echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_24.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
            curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_24.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
            ;;
        "22.04")
            echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
            curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
            ;;
        "20.04")
            echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
            curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
            ;;
        *)
            print_message "$RED" "Unsupported Ubuntu version: $version"
            exit 1
            ;;
    esac
    
    print_message "$BLUE" "Updating package lists..."
    sudo apt update
    
    # Install dependencies first
    install_dependencies
    
    print_message "$BLUE" "Installing Zeek LTS..."
    # Try to install with apt
    if ! sudo apt install -y zeek-lts; then
        print_message "$YELLOW" "Encountered issues with installation. Attempting to fix with apt..."
        # Fix broken dependencies and try again
        sudo apt --fix-broken install -y
        sudo apt install -y zeek-lts
    fi
    
    # Verify installation
    if command -v zeek &> /dev/null; then
        print_message "$GREEN" "Zeek has been successfully installed!"
        zeek --version
        print_message "$GREEN" "Installation completed! Zeek is installed at /opt/zeek/"
    else
        print_message "$RED" "Failed to install Zeek. Please check the error messages above."
        exit 1
    fi
}

# Install required dependencies
install_dependencies() {
    print_message "$BLUE" "Installing required dependencies..."
    
    # Install mandatory packages
    sudo apt install -y \
        libpcap0.8 \
        libmaxminddb0 \
        libpcap-dev \
        libssl-dev \
        zlib1g-dev \
        libmaxminddb-dev \
        python3 \
        mailutils \
        zlib1g \
        build-essential \
        cmake \
        make \
        gcc \
        g++
        
    # Check for architecture-specific packages
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then
        # amd64 specific packages that might be needed
        sudo apt install -y \
            libpcap0.8:amd64 \
            libmaxminddb0:amd64 \
            libssl3:amd64 \
            zlib1g:amd64 \
            libpcap-dev:amd64 \
            libssl-dev:amd64 \
            zlib1g-dev:amd64 \
            libmaxminddb-dev:amd64 \
            python3:amd64 || true  # Continue even if some packages are not found
    fi
    
    # Fix any broken dependencies
    print_message "$BLUE" "Fixing any broken dependencies..."
    sudo apt --fix-broken install -y
    
    print_message "$GREEN" "All dependencies have been installed."
}

# Show menu for Ubuntu version selection
show_menu() {
    print_message "$PURPLE" "===== Zeek Installation Script ====="
    print_message "$CYAN" "Please select your Ubuntu version:"
    print_message "$CYAN" "1) Ubuntu 25.04"
    print_message "$CYAN" "2) Ubuntu 24.10"
    print_message "$CYAN" "3) Ubuntu 24.04"
    print_message "$CYAN" "4) Ubuntu 22.04"
    print_message "$CYAN" "5) Ubuntu 20.04"
    print_message "$CYAN" "6) Auto-detect version"
    print_message "$CYAN" "7) Exit"
    
    read -p "Enter your choice (1-7): " choice
    
    case $choice in
        1)
            install_zeek "25.04"
            ;;
        2)
            install_zeek "24.10"
            ;;
        3)
            install_zeek "24.04"
            ;;
        4)
            install_zeek "22.04"
            ;;
        5)
            install_zeek "20.04"
            ;;
        6)
            get_ubuntu_version
            install_zeek "$OS_VERSION"
            ;;
        7)
            print_message "$GREEN" "Exiting setup script."
            exit 0
            ;;
        *)
            print_message "$RED" "Invalid choice. Please select a number between 1 and 7."
            show_menu
            ;;
    esac
}

# Main function
main() {
    print_message "$PURPLE" "===== Zeek Installation Script ====="
    check_gpg
    check_zeek_installation
    show_menu
    setup_env_variables
    
    print_message "$GREEN" "Zeek installation completed successfully!"
    print_message "$BLUE" "You can verify the installation by running: zeek -h"
}

# Execute main function
main
