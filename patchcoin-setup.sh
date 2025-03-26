#!/bin/bash
# Patchcoin setup script

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

set -e

print_usage() {
    echo "Usage: $0 [OPTION]"
    echo "Install or uninstall Patchcoin."
    echo ""
    echo "Options:"
    echo "  --install    Install Patchcoin (default if no option provided)"
    echo "  --uninstall  Uninstall Patchcoin"
    echo "  --help       Display this help and exit"
    exit 1
}

detect_architecture() {
    local machine=$(uname -m)
    local os=$(uname -s)

    ARCH="x86_64"
    OS_SUFFIX="linux-gnu"

    case "$machine" in
        x86_64)
            ARCH="x86_64"
            OS_SUFFIX="linux-gnu"
            ;;
        aarch64|arm64)
            ARCH="aarch64"
            OS_SUFFIX="linux-gnu"
            ;;
        armv7*|armhf)
            ARCH="arm"
            OS_SUFFIX="linux-gnueabihf"
            ;;
        riscv64)
            ARCH="riscv64"
            OS_SUFFIX="linux-gnu"
            ;;
        *)
            echo "Warning: Unsupported architecture: $machine"
            echo "Defaulting to x86_64-linux-gnu"
            ;;
    esac
    
    echo "Detected architecture: $ARCH"
    echo "Detected OS suffix: $OS_SUFFIX"
}

check_sha256() {
    local file="$1"
    local expected_hash="$2"

    if ! command -v sha256sum &> /dev/null; then
        echo "sha256sum not found, installing..."
        apt-get update
        apt-get install -y coreutils
    fi

    echo "Verifying SHA256 checksum..."
    local actual_hash=$(sha256sum "$file" | awk '{print $1}')

    if [ "$actual_hash" != "$expected_hash" ]; then
        echo "ERROR: SHA256 verification failed!"
        echo "Expected: $expected_hash"
        echo "Actual:   $actual_hash"
        echo "The downloaded file may be corrupted or tampered with."
        return 1
    else
        echo "SHA256 verification successful."
        return 0
    fi
}

install_patchcoin() {
    echo "Starting Patchcoin installation..."

    COMMIT_HASH=ce463154e90f
    APP_VERSION=0.1.0
    APP_NAME=patchcoin

    detect_architecture

    TARBALL_URL="https://github.com/${APP_NAME}/${APP_NAME}/releases/download/v${APP_VERSION}ptc/${APP_NAME}-${COMMIT_HASH}-${ARCH}-${OS_SUFFIX}.tar.gz"
    TARBALL_NAME="${APP_NAME}-${COMMIT_HASH}-${ARCH}-${OS_SUFFIX}.tar.gz"
    LOGO_URL="https://raw.githubusercontent.com/patchcoin/patchcoin/refs/heads/main/share/pixmaps/patchcoin128.png"

    EXPECTED_SHA256=""
    case "${ARCH}-${OS_SUFFIX}" in
        "x86_64-linux-gnu")
            EXPECTED_SHA256="1ecc45ca035e22cc7d3332658b82a7350bb8d57658f15f555b57a04f698b38c8"
            ;;
        "aarch64-linux-gnu")
            EXPECTED_SHA256="98e42ae251230ff9abc904d0c71449fc07ad743c3b608ebf822d7f0f9f994555"
            ;;
        "arm-linux-gnueabihf")
            EXPECTED_SHA256="88c274e484a6d7246facf0239c1b0bf800f26f06e6fc5d43e71b1a75fb68fae0"
            ;;
        "riscv64-linux-gnu")
            EXPECTED_SHA256="d256a178a60282d46cd3b3321866a1632a0f89c2d4d3db3fe45a7a4cd7996a2e"
            ;;
        *)
            echo "Warning: No SHA256 hash available for this architecture."
            echo "Security verification will be skipped."
            ;;
    esac

    echo "Installing prerequisites..."
    apt-get update
    apt-get install -y curl

    echo "Creating temporary working directory..."
    TEMP_DIR=$(mktemp -d)
    cd "${TEMP_DIR}"

    echo "Downloading Patchcoin tarball..."
    curl -L -o ${TARBALL_NAME} ${TARBALL_URL}

    if [ -n "$EXPECTED_SHA256" ]; then
        if ! check_sha256 "${TARBALL_NAME}" "${EXPECTED_SHA256}"; then
            echo "Installation aborted due to SHA256 verification failure."
            cd /
            rm -rf "${TEMP_DIR}"
            exit 1
        fi
    fi

    echo "Extracting tarball..."
    tar xzf ${TARBALL_NAME}

    echo "Installing binaries..."
    BINARIES=("${APP_NAME}-qt" "${APP_NAME}-wallet" "${APP_NAME}d" "${APP_NAME}-cli" "${APP_NAME}-tx" "${APP_NAME}-util")
    for binary in "${BINARIES[@]}"; do
        install -Dm755 "${APP_NAME}-${COMMIT_HASH}/bin/${binary}" "/usr/local/bin/${binary}"
        echo "  - Installed ${binary}"
    done

    echo "Installing libraries..."
    mkdir -p /usr/local/lib
    install -Dm755 ${APP_NAME}-${COMMIT_HASH}/lib/libpeercoinconsensus.so.0.0.0 /usr/local/lib/libpeercoinconsensus.so.0.0.0
    ln -sf /usr/local/lib/libpeercoinconsensus.so.0.0.0 /usr/local/lib/libpeercoinconsensus.so.0
    ln -sf /usr/local/lib/libpeercoinconsensus.so.0.0.0 /usr/local/lib/libpeercoinconsensus.so
    ldconfig

    echo "Downloading logo..."
    mkdir -p /usr/share/pixmaps
    curl -L -o /usr/share/pixmaps/${APP_NAME}128.png ${LOGO_URL}

    echo "Setting up desktop environment..."
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/${APP_NAME}-qt.desktop << EOF
[Desktop Entry]
Name=Patchcoin
Comment=Patchcoin Qt wallet
Exec=${APP_NAME}-qt %u
Terminal=false
Type=Application
Icon=${APP_NAME}128
Categories=Office;Finance;
EOF

    echo "Cleaning up..."
    cd /
    rm -rf "${TEMP_DIR}"

    echo "Patchcoin ${APP_VERSION} (${COMMIT_HASH}) installation complete!"
    echo "The following programs are now available:"
    echo "  - ${APP_NAME}-qt       (GUI wallet)"
    echo "  - ${APP_NAME}d         (Daemon)"
    echo "  - ${APP_NAME}-cli      (Command-line interface)"
    echo "  - ${APP_NAME}-tx       (Transaction tool)"
    echo "  - ${APP_NAME}-wallet   (Wallet tool)"
    echo "  - ${APP_NAME}-util     (Utility)"
    echo ""
    echo "You can find the GUI wallet in your system's application menu."
}

uninstall_patchcoin() {
    echo "Starting Patchcoin uninstallation..."
    APP_NAME=patchcoin

    echo "Removing binaries..."
    BINARIES=("${APP_NAME}-qt" "${APP_NAME}-wallet" "${APP_NAME}d" "${APP_NAME}-cli" "${APP_NAME}-tx" "${APP_NAME}-util")
    for binary in "${BINARIES[@]}"; do
        if [ -f "/usr/local/bin/${binary}" ]; then
            rm -f "/usr/local/bin/${binary}"
            echo "  - Removed ${binary}"
        fi
    done

    echo "Removing libraries..."
    if [ -f "/usr/local/lib/libpeercoinconsensus.so.0.0.0" ]; then
        rm -f /usr/local/lib/libpeercoinconsensus.so.0.0.0
        echo "  - Removed libpeercoinconsensus.so.0.0.0"
    fi
    if [ -L "/usr/local/lib/libpeercoinconsensus.so.0" ]; then
        rm -f /usr/local/lib/libpeercoinconsensus.so.0
        echo "  - Removed libpeercoinconsensus.so.0"
    fi
    if [ -L "/usr/local/lib/libpeercoinconsensus.so" ]; then
        rm -f /usr/local/lib/libpeercoinconsensus.so
        echo "  - Removed libpeercoinconsensus.so"
    fi
    ldconfig

    echo "Removing desktop files..."
    if [ -f "/usr/share/applications/${APP_NAME}-qt.desktop" ]; then
        rm -f "/usr/share/applications/${APP_NAME}-qt.desktop"
        echo "  - Removed desktop file"
    fi

    if [ -f "/usr/share/pixmaps/${APP_NAME}128.png" ]; then
        rm -f "/usr/share/pixmaps/${APP_NAME}128.png"
        echo "  - Removed icon"
    fi

    echo "Patchcoin uninstallation complete!"
}

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

if [ $# -eq 0 ]; then
    install_patchcoin
    exit 0
fi

case "$1" in
    --install)
        install_patchcoin
        ;;
    --uninstall)
        uninstall_patchcoin
        ;;
    --help)
        print_usage
        ;;
    *)
        echo "Unknown option: $1"
        print_usage
        ;;
esac

exit 0
