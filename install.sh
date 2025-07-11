#!/bin/bash

# Laravel Deployment Tool (laradep) Installer
# Install script for laradep and zsh completions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="https://github.com/jeromecoloma/laradep"
INSTALL_DIR="$HOME/bin"
COMPLETION_DIR="$HOME/.zsh/completions"
SCRIPT_NAME="laradep"

# Get latest version from GitHub (will be fetched dynamically)
get_latest_version() {
    local latest_version=""
    if command_exists "curl"; then
        latest_version=$(curl -fsSL "$GITHUB_REPO/raw/main/laradep" | grep 'LARADEP_VERSION=' | head -1 | cut -d'"' -f2 2>/dev/null || echo "")
    elif command_exists "wget"; then
        latest_version=$(wget -qO- "$GITHUB_REPO/raw/main/laradep" | grep 'LARADEP_VERSION=' | head -1 | cut -d'"' -f2 2>/dev/null || echo "")
    fi
    
    if [ -n "$latest_version" ]; then
        echo "$latest_version"
    else
        echo "latest"
    fi
}

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    local version=$(get_latest_version)
    echo -e "${CYAN}"
    echo "╭─────────────────────────────────────────────────────────────╮"
    echo "│                                                             │"
    echo "│    🚀  Laravel Deployment Tool (laradep) Installer v$version   │"
    echo "│                                                             │"
    echo "╰─────────────────────────────────────────────────────────────╯"
    echo -e "${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists "curl" && ! command_exists "wget"; then
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    if ! command_exists "zsh"; then
        print_warning "Zsh not found. Completion will be installed but may not work until zsh is installed."
    fi
    
    print_success "Prerequisites check passed"
}

# Create directories
create_directories() {
    print_status "Creating installation directories..."
    
    # Create ~/bin directory
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
        print_success "Created $INSTALL_DIR"
    else
        print_status "$INSTALL_DIR already exists"
    fi
    
    # Create zsh completions directory
    if [ ! -d "$COMPLETION_DIR" ]; then
        mkdir -p "$COMPLETION_DIR"
        print_success "Created $COMPLETION_DIR"
    else
        print_status "$COMPLETION_DIR already exists"
    fi
}

# Check if laradep is already installed and compare versions
check_existing_installation() {
    local script_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    if [ -f "$script_path" ] && [ -x "$script_path" ]; then
        print_status "Existing installation found"
        
        # Get current installed version
        local current_version=""
        if command_exists "$SCRIPT_NAME"; then
            current_version=$("$SCRIPT_NAME" --version 2>/dev/null | grep -o 'v[0-9.]*' | sed 's/v//' || echo "unknown")
        fi
        
        # Get latest version from GitHub
        local latest_version=""
        if command_exists "curl"; then
            latest_version=$(curl -fsSL "$GITHUB_REPO/raw/main/laradep" | grep 'LARADEP_VERSION=' | head -1 | cut -d'"' -f2 2>/dev/null || echo "")
        elif command_exists "wget"; then
            latest_version=$(wget -qO- "$GITHUB_REPO/raw/main/laradep" | grep 'LARADEP_VERSION=' | head -1 | cut -d'"' -f2 2>/dev/null || echo "")
        fi
        
        if [ -n "$current_version" ] && [ -n "$latest_version" ]; then
            print_status "Current version: v$current_version"
            print_status "Latest version: v$latest_version"
            
            if [ "$current_version" = "$latest_version" ]; then
                print_success "You already have the latest version installed!"
                if [ "${FORCE_INSTALL:-}" != "1" ]; then
                    read -p "Do you want to reinstall anyway? (y/N): " -n 1 -r
                    echo
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        print_status "Installation cancelled"
                        exit 0
                    fi
                fi
            else
                print_warning "A newer version is available"
                print_status "Updating from v$current_version to v$latest_version"
            fi
        else
            print_warning "Could not determine version information"
        fi
        
        return 0
    else
        print_status "No existing installation found"
        return 1
    fi
}

# Download and install laradep script
install_laradep() {
    print_status "Installing laradep script..."
    
    local script_path="$INSTALL_DIR/$SCRIPT_NAME"
    local download_url="$GITHUB_REPO/raw/main/laradep"
    local temp_file=$(mktemp)
    
    # Download to temporary file first
    if command_exists "curl"; then
        if ! curl -fsSL "$download_url" -o "$temp_file"; then
            print_error "Failed to download laradep script"
            rm -f "$temp_file"
            return 1
        fi
    elif command_exists "wget"; then
        if ! wget -q "$download_url" -O "$temp_file"; then
            print_error "Failed to download laradep script"
            rm -f "$temp_file"
            return 1
        fi
    fi
    
    # Verify the download
    if [ ! -s "$temp_file" ]; then
        print_error "Downloaded file is empty"
        rm -f "$temp_file"
        return 1
    fi
    
    # Check if it's a valid script
    if ! head -1 "$temp_file" | grep -q "#!/bin/bash"; then
        print_error "Downloaded file doesn't appear to be a valid script"
        rm -f "$temp_file"
        return 1
    fi
    
    # Create backup of existing file if it exists
    if [ -f "$script_path" ]; then
        cp "$script_path" "${script_path}.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Created backup of existing installation"
    fi
    
    # Move to final location and make executable
    mv "$temp_file" "$script_path"
    chmod +x "$script_path"
    
    print_success "laradep installed to $script_path"
}

# Download and install zsh completion
install_completion() {
    print_status "Installing zsh completion..."
    
    local completion_path="$COMPLETION_DIR/_laradep"
    local download_url="$GITHUB_REPO/raw/main/completions/_laradep"
    local temp_file=$(mktemp)
    
    # Download to temporary file first
    if command_exists "curl"; then
        if ! curl -fsSL "$download_url" -o "$temp_file"; then
            print_warning "Failed to download completion file (non-critical)"
            rm -f "$temp_file"
            return 1
        fi
    elif command_exists "wget"; then
        if ! wget -q "$download_url" -O "$temp_file"; then
            print_warning "Failed to download completion file (non-critical)"
            rm -f "$temp_file"
            return 1
        fi
    fi
    
    # Verify the download
    if [ ! -s "$temp_file" ]; then
        print_warning "Downloaded completion file is empty (non-critical)"
        rm -f "$temp_file"
        return 1
    fi
    
    # Create backup of existing completion if it exists
    if [ -f "$completion_path" ]; then
        cp "$completion_path" "${completion_path}.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Created backup of existing completion"
    fi
    
    # Move to final location
    mv "$temp_file" "$completion_path"
    
    print_success "Zsh completion installed to $completion_path"
}

# Check if ~/bin is in PATH
check_path() {
    print_status "Checking PATH configuration..."
    
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        print_warning "$INSTALL_DIR is not in your PATH"
        print_status "To fix this, add the following line to your shell config file:"
        print_status "  ~/.zshrc (for zsh) or ~/.bashrc (for bash):"
        echo ""
        echo -e "${YELLOW}export PATH=\"\$HOME/bin:\$PATH\"${NC}"
        echo ""
        print_status "Then restart your shell or run: source ~/.zshrc"
        return 1
    else
        print_success "$INSTALL_DIR is already in your PATH"
        return 0
    fi
}

# Configure zsh completions
configure_completions() {
    print_status "Configuring zsh completions..."
    
    local zshrc="$HOME/.zshrc"
    local completion_config="fpath=(\$HOME/.zsh/completions \$fpath)"
    local autoload_config="autoload -U compinit && compinit"
    
    if [ -f "$zshrc" ]; then
        # Check if completion path is already configured
        if ! grep -q "fpath=.*\.zsh/completions" "$zshrc"; then
            print_status "Adding completion configuration to ~/.zshrc"
            echo "" >> "$zshrc"
            echo "# Laradep completion configuration" >> "$zshrc"
            echo "$completion_config" >> "$zshrc"
            echo "$autoload_config" >> "$zshrc"
            print_success "Completion configuration added to ~/.zshrc"
        else
            print_status "Completion configuration already exists in ~/.zshrc"
        fi
    else
        print_warning "~/.zshrc not found. Creating basic configuration..."
        echo "# Laradep completion configuration" > "$zshrc"
        echo "$completion_config" >> "$zshrc"
        echo "$autoload_config" >> "$zshrc"
        print_success "Created ~/.zshrc with completion configuration"
    fi
}

# Test installation
test_installation() {
    print_status "Testing installation..."
    
    if [ -x "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        if command_exists "$SCRIPT_NAME"; then
            local version=$("$SCRIPT_NAME" --version 2>/dev/null | grep 'Version:' | awk '{print $2}' || echo "unknown")
            print_success "laradep $version is working correctly"
        else
            print_warning "laradep installed but not in PATH. You may need to restart your shell."
        fi
    else
        print_error "Installation verification failed"
        return 1
    fi
}

# Main installation function
main() {
    print_header
    
    print_status "Starting laradep installation..."
    local latest_version=$(get_latest_version)
    if [ "$latest_version" != "latest" ]; then
        print_status "Installing version: v$latest_version"
    fi
    echo ""
    
    check_prerequisites
    create_directories

    # Handle existing installation check properly
    if check_existing_installation; then
        print_status "Proceeding with installation/update..."
    else
        print_status "Proceeding with fresh installation..."
    fi

    install_laradep
    install_completion
    
    echo ""
    print_status "Installation completed!"
    echo ""
    
    local path_ok=0
    check_path || path_ok=1
    configure_completions
    
    echo ""
    
    if [ $path_ok -eq 0 ]; then
        test_installation
        echo ""
        print_success "🎉 Installation successful!"
        print_status "You can now use: laradep --help"
        
        if command_exists "zsh"; then
            print_status "Restart your zsh shell to enable tab completion"
        fi
    else
        print_success "🎉 Installation completed!"
        print_warning "Please add ~/bin to your PATH and restart your shell"
        print_status "Then run: laradep --help"
    fi
    
    echo ""
    print_status "Documentation: $GITHUB_REPO"
    print_status "Report issues: $GITHUB_REPO/issues"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Laravel Deployment Tool (laradep) Installer"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h      Show this help message"
        echo "  --update        Update to latest version"
        echo "  --force         Force reinstall even if up to date"
        echo "  --uninstall     Uninstall laradep"
        echo ""
        echo "Installation locations:"
        echo "  Script: $INSTALL_DIR/$SCRIPT_NAME"
        echo "  Completion: $COMPLETION_DIR/_laradep"
        echo ""
        echo "Examples:"
        echo "  $0              # Install or update laradep"
        echo "  $0 --update     # Update to latest version"
        echo "  $0 --force      # Force reinstall current version"
        echo "  $0 --uninstall  # Remove laradep"
        exit 0
        ;;
    --update)
        FORCE_INSTALL=0
        main
        ;;
    --force)
        FORCE_INSTALL=1
        main
        ;;
    --uninstall)
        print_header
        print_status "Uninstalling laradep..."
        
        # Remove script
        if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
            rm "$INSTALL_DIR/$SCRIPT_NAME"
            print_success "Removed $INSTALL_DIR/$SCRIPT_NAME"
        fi
        
        # Remove backups (optional)
        if ls "$INSTALL_DIR/$SCRIPT_NAME.backup."* >/dev/null 2>&1; then
            read -p "Remove backup files too? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm "$INSTALL_DIR/$SCRIPT_NAME.backup."*
                print_success "Removed backup files"
            fi
        fi
        
        # Remove completion
        if [ -f "$COMPLETION_DIR/_laradep" ]; then
            rm "$COMPLETION_DIR/_laradep"
            print_success "Removed $COMPLETION_DIR/_laradep"
        fi
        
        # Remove completion backups (optional)
        if ls "$COMPLETION_DIR/_laradep.backup."* >/dev/null 2>&1; then
            rm "$COMPLETION_DIR/_laradep.backup."*
            print_success "Removed completion backup files"
        fi
        
        print_warning "Note: PATH and completion configurations in ~/.zshrc were not removed"
        print_success "Uninstallation completed"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        print_status "Use --help for usage information"
        exit 1
        ;;
esac
