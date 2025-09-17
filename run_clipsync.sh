#!/bin/bash
set -e

VENV_DIR="venv"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists python3; then
    echo "Error: python3 is not installed. Please install python3 first."
    exit 1
fi

check_and_install_venv() {
    if command_exists apt-get; then
        if ! python3 -m venv --help >/dev/null 2>&1; then
            echo "python3-venv is not available. Installing..."
            sudo apt-get update && sudo apt-get install -y python3-venv
        fi
    elif command_exists yum; then
        if ! python3 -m venv --help >/dev/null 2>&1; then
            echo "python3-venv is not available. Installing..."
            sudo yum install -y python3-venv
        fi
    elif command_exists pacman; then
        if ! python3 -m venv --help >/dev/null 2>&1; then
            echo "Warning: python3-venv not available. Try installing python with: sudo pacman -S python"
        fi
    fi
}

check_and_install_venv

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
else
    echo "Virtual environment already exists."
fi

echo "Activating virtual environment..."
source venv/bin/activate || {
    echo "Error: Failed to activate virtual environment"
    exit 1
}

echo "Upgrading pip..."
pip install --upgrade pip || echo "Warning: Failed to upgrade pip, continuing..."

if [ -f requirements.txt ]; then
    echo "Installing requirements..."
    pip install -r requirements.txt || { echo "Error: Failed to install requirements"; exit 1; }
else
    echo "Warning: requirements.txt not found"
fi

# Install clipboard tools if not present
echo "Checking clipboard tools..."
if ! command_exists xclip || ! command_exists xsel; then
    echo "Installing clipboard tools (xclip, xsel)..."
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y xclip xsel || echo "Warning: Failed to install clipboard tools."
    elif command_exists yum; then
        sudo yum install -y xclip xsel || echo "Warning: Failed to install clipboard tools."
    elif command_exists pacman; then
        sudo pacman -S --noconfirm xclip xsel || echo "Warning: Failed to install clipboard tools."
    else
        echo "Warning: Unknown package manager. Please install xclip and xsel manually."
    fi
else
    echo "Clipboard tools already installed."
fi

# Check that the main Python file exists
if [ ! -f "clip_sync.py" ]; then
    echo "Error: clip_sync.py not found in the current directory"
    exit 1
fi

# Run ClipSync
echo "Running ClipSync..."
python clip_sync.py "$@" || { echo "Error: ClipSync failed to run"; exit 1; }
