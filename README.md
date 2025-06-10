# Patchcoin Setup

This README provides instructions for installing and uninstalling Patchcoin using the `patchcoin-setup.sh` script.

## Getting the Script

There are two ways to obtain the installation script:

1. Clone the repository:
   ```
   git clone https://github.com/patchcoin/linux-install-helper.git
   cd linux-install-helper
   ```

2. Download the script directly:
   ```
   curl -O https://raw.githubusercontent.com/patchcoin/linux-install-helper/refs/heads/master/patchcoin-setup.sh
   ```

## Requirements

- Root privileges
- Debian-based Linux distribution (Ubuntu, Debian, etc.)
- Internet connection

## Installation

1. Make the script executable:
   ```
   chmod +x patchcoin-setup.sh
   ```

2. Run the script with root privileges:
   ```
   sudo ./patchcoin-setup.sh
   ```

   Or explicitly use the install option:
   ```
   sudo ./patchcoin-setup.sh --install
   ```

## Uninstallation

To uninstall Patchcoin:
```
sudo ./patchcoin-setup.sh --uninstall
```

## Available Components

After installation, the following components will be available:

- `patchcoin-qt` - GUI wallet
- `patchcoind` - Daemon
- `patchcoin-cli` - Command-line interface
- `patchcoin-tx` - Transaction tool
- `patchcoin-wallet` - Wallet tool
- `patchcoin-util` - Utility

## Usage Options

```
Usage: ./patchcoin-setup.sh [OPTION]
Install or uninstall Patchcoin.

Options:
  --install    Install Patchcoin (default if no option provided)
  --uninstall  Uninstall Patchcoin
  --help       Display this help and exit
```

## Supported Architectures

The script automatically detects and supports the following architectures:
- x86_64 (64-bit Intel/AMD)
- aarch64/arm64 (64-bit ARM)
- armv7/armhf (32-bit ARM)
- riscv64 (64-bit RISC-V)

## Notes

- The script requires an internet connection to download the necessary files.
- Installation creates desktop entries for easy access to the GUI wallet.
- After installation, the Patchcoin GUI wallet will be available in your system's start menu/application launcher.
- The current version installed is 0.1.1.
