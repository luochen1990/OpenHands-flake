# Example Home Manager configuration for OpenHands
# This can be included in your home.nix

{ config, lib, pkgs, ... }:

let
  # Import the OpenHands flake
  openhands = builtins.getFlake "github:luochen1990/OpenHands-flake";
in {
  # Add the OpenHands package to your environment
  home.packages = [
    openhands.packages.${pkgs.system}.openhands
  ];
  
  # Create a systemd user service to run OpenHands
  systemd.user.services.openhands = {
    Unit = {
      Description = "OpenHands AI software engineer";
      After = [ "network.target" ];
    };
    
    Service = {
      ExecStart = "${openhands.packages.${pkgs.system}.openhands}/bin/openhands-server";
      WorkingDirectory = "${config.home.homeDirectory}/.openhands";
      Environment = [
        "BACKEND_HOST=127.0.0.1"
        "BACKEND_PORT=3000"
        "WORKSPACE_BASE=${config.home.homeDirectory}/.openhands/workspace"
        "SERVE_FRONTEND=true"
      ];
      Restart = "on-failure";
      RestartSec = "5s";
    };
    
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
  
  # Create the OpenHands directory structure
  home.activation.createOpenHandsDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${config.home.homeDirectory}/.openhands/workspace
    
    # Create a basic config.toml if it doesn't exist
    if [ ! -f ${config.home.homeDirectory}/.openhands/config.toml ]; then
      $DRY_RUN_CMD cat > ${config.home.homeDirectory}/.openhands/config.toml << EOF
[core]
workspace_base="${config.home.homeDirectory}/.openhands/workspace"

[llm]
model="gpt-4o"
# Add your API key here or set it in the environment
# api_key="your-api-key-here"
EOF
    fi
  '';
}