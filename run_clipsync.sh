#!/bin/bash
set -e

# URL של הפרויקט
#REPO_URL="https://github.com/idanless/ClipSync.git"
PROJECT_DIR="ClipSync"
VENV_DIR="$PROJECT_DIR/venv"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists git; then
    echo "Error: git is not installed. Please install git first."
    exit 1
fi

if ! command_exists python3; then
    echo "Error: python3 is not installed. Please install python3 first."
    exit 1
fi

check_and_install_venv() {
    if command_exists apt-get; then
        # בדיקה אם python3-venv זמין
        if ! python3 -m venv --help >/dev/null 2>&1; then
            echo "python3-venv is not available. Installing..."
            if ! sudo apt-get update && sudo apt-get install -y python3-venv; then
                echo "Error: Failed to install python3-venv"
                exit 1
            fi
        fi
    elif command_exists yum; then
        if ! python3 -m venv --help >/dev/null 2>&1; then
            echo "python3-venv is not available. Installing..."
            if ! sudo yum install -y python3-venv; then
                echo "Error: Failed to install python3-venv"
                exit 1
            fi
        fi
    elif command_exists pacman; then
        # ב-Arch Linux, venv כלול בדרך כלל
        if ! python3 -m venv --help >/dev/null 2>&1; then
            echo "Warning: python3-venv not available. Try installing python with: sudo pacman -S python"
        fi
    fi
}

check_and_install_venv

# הורדת הפרויקט או עדכון אם קיים
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Cloning repository..."
    if ! git clone "$REPO_URL"; then
        echo "Error: Failed to clone repository"
        exit 1
    fi
else
    echo "Directory $PROJECT_DIR already exists, pulling latest changes..."
    if ! git -C "$PROJECT_DIR" pull; then
        echo "Warning: Failed to pull latest changes, continuing with existing code..."
    fi
fi

cd "$PROJECT_DIR" || {
    echo "Error: Failed to enter $PROJECT_DIR directory"
    exit 1
}

# יצירת virtual environment אם לא קיים
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    if ! python3 -m venv venv; then
        echo "Error: Failed to create virtual environment"
        echo "Try running: sudo apt install python3-venv"
        exit 1
    fi
else
    echo "Virtual environment already exists."
fi

echo "Activating virtual environment..."
source venv/bin/activate || {
    echo "Error: Failed to activate virtual environment"
    exit 1
}

echo "Upgrading pip..."
if ! pip install --upgrade pip; then
    echo "Warning: Failed to upgrade pip, continuing..."
fi

if [ -f requirements.txt ]; then
    echo "Installing requirements..."
    if ! pip install -r requirements.txt; then
        echo "Error: Failed to install requirements"
        exit 1
    fi
else
    echo "Warning: requirements.txt not found"
fi

echo "Checking clipboard tools..."
if ! command_exists xclip || ! command_exists xsel; then
    echo "Installing clipboard tools (xclip, xsel)..."
    if command_exists apt-get; then
        if ! sudo apt-get update && sudo apt-get install -y xclip xsel; then
            echo "Warning: Failed to install clipboard tools. Some features might not work."
        fi
    elif command_exists yum; then
        if ! sudo yum install -y xclip xsel; then
            echo "Warning: Failed to install clipboard tools. Some features might not work."
        fi
    elif command_exists pacman; then
        if ! sudo pacman -S --noconfirm xclip xsel; then
            echo "Warning: Failed to install clipboard tools. Some features might not work."
        fi
    else
        echo "Warning: Unknown package manager. Please install xclip and xsel manually."
    fi
else
    echo "Clipboard tools already installed."
fi

if [ ! -f "clip_sync.py" ]; then
    echo "Error: clip_sync.py not found in $PROJECT_DIR"
    exit 1
fi

# הרצת הקוד
echo "Running ClipSync..."
if ! python clip_sync.py "$@"; then
    echo "Error: ClipSync failed to run"
    exit 1
fi
