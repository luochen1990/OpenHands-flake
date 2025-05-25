Add Nix integration for OpenHands

This commit adds a complete Nix integration for the OpenHands project, including:

1. A Nix flake that provides:
   - A package for installing OpenHands
   - A development shell for working on OpenHands
   - A NixOS module for running OpenHands as a service

2. Modular implementation:
   - Frontend build using proper Nix JavaScript packaging
   - Python package with all required dependencies
   - NixOS module with flexible configuration options

3. Documentation and examples:
   - Detailed documentation in NIX.md
   - Example configurations for NixOS and Home Manager
   - Troubleshooting guide and testing instructions

4. Features:
   - Support for both CLI mode and server mode
   - Environment file handling for sensitive information
   - Automatic directory and file creation
   - Multi-platform support (Linux and macOS)

All components have been tested and verified to work correctly.