#!/bin/bash

# Function to check if Python 3.11 is installed
check_python311() {
    if ! command -v python3.11 &> /dev/null; then
        echo "Python 3.11 is not installed."
        echo "Please install Python 3.11 using:"
        echo "  brew install python@3.11"
        exit 1
    fi
}

# Function to set up virtual environment
setup_venv() {
    local dir=$1
    echo "Setting up virtual environment in $dir..."
    
    # Remove existing venv if it exists
    if [ -d "$dir/venv" ]; then
        echo "Removing existing virtual environment..."
        rm -rf "$dir/venv"
    fi
    
    # Create new virtual environment with Python 3.11
    python3.11 -m venv "$dir/venv"
    
    # Activate virtual environment
    source "$dir/venv/bin/activate"
    
    # Upgrade pip
    python3 -m pip install --upgrade pip
    
    # Install requirements if requirements.txt exists
    if [ -f "$dir/requirements.txt" ]; then
        echo "Installing requirements..."
        pip install -r "$dir/requirements.txt"
    fi
}

# Function to configure shell for automatic activation
configure_shell() {
    local project_dir=$(pwd)
    local activation_command="cd \"$project_dir\" && source backend/venv/bin/activate"
    local shell_rc=""
    
    # Detect shell type
    if [[ $SHELL == */zsh ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ $SHELL == */bash ]]; then
        shell_rc="$HOME/.bashrc"
    else
        echo "Unsupported shell: $SHELL"
        return 1
    fi
    
    # Add activation command to shell config if not already present
    if ! grep -q "neurolearn-ai automatic activation" "$shell_rc"; then
        echo "" >> "$shell_rc"
        echo "# neurolearn-ai automatic activation" >> "$shell_rc"
        echo "if [ -f \"$project_dir/backend/venv/bin/activate\" ]; then" >> "$shell_rc"
        echo "    $activation_command" >> "$shell_rc"
        echo "fi" >> "$shell_rc"
        echo "Added automatic activation to $shell_rc"
    fi
}

# Main script
echo "Setting up NeuroLearn development environment..."

# Check for Python 3.11
check_python311

# Set up backend environment
if [ -d "backend" ]; then
    setup_venv "backend"
fi

# Configure shell for automatic activation
echo ""
echo "Would you like to configure automatic virtual environment activation? (y/n)"
read -r configure_auto_activate

if [[ $configure_auto_activate =~ ^[Yy]$ ]]; then
    configure_shell
    echo ""
    echo "Configuration added to your shell's startup file."
    echo "Please restart your terminal or run 'source ~/.zshrc' (for zsh) or 'source ~/.bashrc' (for bash) to apply changes."
fi

# Activate the virtual environment in the current shell
source "backend/venv/bin/activate"

echo ""
echo "Setup complete! Virtual environment is now activated."
echo "The virtual environment will be automatically activated when you open this project directory."
echo "You can manually activate it anytime using:"
echo "  source backend/venv/bin/activate" 