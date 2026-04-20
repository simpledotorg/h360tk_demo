#!/bin/bash

# Ensure script stops on first error
set -e

# --- Helper Functions ---
check_docker() { docker version >/dev/null 2>&1; }

check_compose() { docker compose version &> /dev/null; }

check_buildx_version() {
    # Returns 0 if version >= 0.17.0, 1 otherwise
    if ! docker buildx version &>/dev/null; then return 1; fi

    current_ver=$(docker buildx version 2>/dev/null | grep -o 'v[0-9.]*' | sed 's/v//')
    # Compare versions using awk (returns 0 for true, 1 for false)
    echo "$current_ver 0.17.0" | awk '{if ($1 >= $2) exit 0; else exit 1}'
}

# Run `docker compose up -d` from workdir. Handles shells where the user is in group "docker"
# in /etc/group but the current session has not picked up that membership yet (docker.sock EACCES).
run_docker_compose_up() {
    local workdir="$1"
    workdir="$(cd "$workdir" && pwd)"

    if docker info >/dev/null 2>&1; then
        ( cd "$workdir" && docker compose up -d )
        return 0
    fi

    if command -v sg >/dev/null 2>&1 && sg docker -c "docker info >/dev/null 2>&1"; then
        echo "Docker socket not usable in this shell; running compose with active 'docker' group (sg docker)..."
        sg docker -c "cd '$workdir' && docker compose up -d"
        return 0
    fi

    echo "--------------------------------------------------"
    echo "ERROR: Cannot connect to Docker (permission denied on /var/run/docker.sock)."
    echo "--------------------------------------------------"
    exit 1
}

# 1. Detect Operating System
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Error: Cannot detect OS. Proceed with manual installation."
    exit 1
fi

echo "Preparing Heart360 Toolkit environment on $OS..."

# 2. Installation Logic
case "$OS" in
    ubuntu)
        if ! check_docker; then
            echo "Installing Docker for Ubuntu..."
            sudo apt-get update -y
            sudo apt-get install -y ca-certificates curl git
            
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt-get update -y
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        else
            echo "Docker is already installed on Ubuntu."
            # Individual check for Compose on Ubuntu
            if ! check_compose; then
                echo "Docker Compose plugin missing. Installing..."
                sudo apt-get update -y
                sudo apt-get install -y docker-compose-plugin
            else
                echo "Docker Compose is already present."
            fi
        fi
        ;;

    amzn)
        if ! check_docker; then
            echo "Installing Docker for Amazon Linux..."
            sudo dnf update -y
            sudo dnf install -y docker git
            sudo systemctl start docker
            sudo systemctl enable docker
        else
            echo "Docker is already installed on Amazon Linux."
        fi

        # Check Docker Compose (Amazon Linux manual binary check)
        if ! check_compose; then
            echo "Installing Docker Compose binary..."
            mkdir -p ~/.docker/cli-plugins/
            curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
            chmod +x ~/.docker/cli-plugins/docker-compose
        else
            echo "Docker Compose is already present."
        fi

        # Check Buildx Version (Amazon Linux specific requirement)
        if ! check_buildx_version; then
            echo "Installing/Updating Docker Buildx (>= 0.17.0)..."
            mkdir -p ~/.docker/cli-plugins/
            curl -SL https://github.com/docker/buildx/releases/download/v0.17.1/buildx-v0.17.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
            chmod +x ~/.docker/cli-plugins/docker-buildx
        else
            echo "Docker Buildx is already up to date (>= 0.17.0)."
        fi
        ;;

    *)
        echo "Unsupported OS: $OS. Proceed with manual installation."
        exit 1
        ;;
esac

# 3. Finalize Permissions
echo "Checking user permissions..."
if groups $USER | grep &>/dev/null "\bdocker\b"; then
    echo "User $USER is already in the docker group."
else
    echo "Adding $USER to the docker group..."
    sudo usermod -aG docker $USER
    echo "Permissions updated."
    echo "--------------------------------------------------"
    echo "Package installation completed for $OS!"
    echo "To run docker without sudo, you MUST run:"
    echo "   newgrp docker"
    echo "OR log out and log back in."
    echo "--------------------------------------------------"
fi

# 4. Deploy application (clone repo if needed, then start stack)
echo "--------------------------------------------------"
echo "Deploying Heart360 Toolkit demo application..."
DEPLOY_BASE="${H360TK_DEPLOY_DIR:-$HOME}"
cd "$DEPLOY_BASE"
H360_DIR="$DEPLOY_BASE/h360tk_demo"
if [ -d "$H360_DIR" ]; then
    echo "Directory $H360_DIR already exists; skipping git clone."
else
    git clone https://github.com/simpledotorg/h360tk_demo.git "$DEPLOY_BASE/h360tk_demo"
fi
cd "$H360_DIR"
run_docker_compose_up "$H360_DIR"
echo "docker compose up -d completed."
echo "See the repository README for service URLs (Grafana, SFTPGo, etc.)."
echo "--------------------------------------------------"
