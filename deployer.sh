#!/bin/bash

# Ensure script stops on first error
set -e

# --- Helper Functions ---
check_docker() { docker version >/dev/null 2>&1; }

check_compose() { docker compose version &> /dev/null; }

MIN_BUILDX_VERSION="0.17.0"

# True if $1 >= $2 (dot-separated versions). Requires sort -V (coreutils).
semver_ge() {
    [ -n "$1" ] && [ -n "$2" ] || return 1
    [ "$(printf '%s\n' "$2" "$1" | sort -V | tail -n1)" = "$1" ]
}

# Parse buildx version from `docker buildx version` (formats differ: upstream vs Amazon Linux builds).
buildx_plugin_version() {
    local out v
    out="$(docker buildx version 2>/dev/null)" || return 1
    # Upstream: line containing github.com/docker/buildx … v0.xx.yy
    v="$(printf '%s\n' "$out" | grep -F 'github.com/docker/buildx' | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
    if [ -n "$v" ]; then printf '%s' "${v#v}"; return 0; fi
    # Some distros: "Version:" / "version" on same or next tokens
    v="$(printf '%s\n' "$out" | grep -iE '^[[:space:]]*version:|[[:space:]]version[[:space:]]*=' | head -n3 | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
    if [ -n "$v" ]; then printf '%s' "${v#v}"; return 0; fi
    # Last resort: first dotted triplet in output (usually the buildx client version comes first)
    v="$(printf '%s\n' "$out" | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
    if [ -n "$v" ]; then printf '%s' "${v#v}"; return 0; fi
    return 1
}

check_buildx_version() {
    if ! docker buildx version &>/dev/null; then return 1; fi
    local v
    v="$(buildx_plugin_version)"
    [ -n "$v" ] || return 1
    semver_ge "$v" "$MIN_BUILDX_VERSION"
}

# Compose resolves CLI plugins from several dirs; ensure user-installed buildx is preferred.
export_docker_cli_plugin_path() {
    local d="${HOME}/.docker/cli-plugins"
    if [ -n "${DOCKER_CLI_PLUGIN_EXTRA_DIRS:-}" ] && printf ':%s:' "$DOCKER_CLI_PLUGIN_EXTRA_DIRS" | grep -Fq ":$d:"; then
        return 0
    fi
    export DOCKER_CLI_PLUGIN_EXTRA_DIRS="${d}${DOCKER_CLI_PLUGIN_EXTRA_DIRS:+:${DOCKER_CLI_PLUGIN_EXTRA_DIRS}}"
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
        export_docker_cli_plugin_path
        if ! check_buildx_version; then
            echo "Installing/Updating Docker Buildx (>= ${MIN_BUILDX_VERSION}) under ~/.docker/cli-plugins/ ..."
            mkdir -p ~/.docker/cli-plugins/
            curl -fsSL https://github.com/docker/buildx/releases/download/v0.17.1/buildx-v0.17.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
            chmod +x ~/.docker/cli-plugins/docker-buildx
        else
            echo "Docker Buildx is already up to date (>= ${MIN_BUILDX_VERSION})."
        fi
        ;;

    *)
        echo "Unsupported OS: $OS. Proceed with manual installation."
        exit 1
        ;;
esac

# 3. Finalize Permissions
echo "Checking user permissions..."
if groups "$USER" | grep &>/dev/null "\bdocker\b"; then
    echo "User $USER is already in the docker group."
else
    echo "Adding $USER to the docker group..."
    sudo usermod -aG docker "$USER"
    echo "Permissions updated."
    echo "To run docker without sudo in this session, run: newgrp docker"
    echo "(or log out and log back in.)"
fi

echo "--------------------------------------------------"
echo "Package installation finished for $OS."
echo "Next: 
echo ""
echo "See README.md for deploying the application."
echo "--------------------------------------------------"
