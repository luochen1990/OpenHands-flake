# Example NixOS configuration for OpenHands
# Save this as a module and import it in your configuration.nix

{ config, lib, pkgs, ... }:

let
  # Import the OpenHands flake
  openhands = builtins.getFlake "github:luochen1990/OpenHands-flake";
in {
  # Import the OpenHands NixOS module
  imports = [
    openhands.nixosModules.default
  ];

  # Configure the OpenHands service
  services.openhands = {
    enable = true;
    
    # Listen on all interfaces (change to 127.0.0.1 for local access only)
    host = "0.0.0.0";
    port = 3000;
    
    # Set the LLM model to use
    llmModel = "gpt-4o";
    
    # For sensitive information like API keys, use an environment file
    environmentFile = "/var/lib/openhands/secrets.env";
    
    # Customize the workspace directory if needed
    workspaceDir = "/var/lib/openhands/workspace";
  };

  # Optional: Open the firewall port
  networking.firewall.allowedTCPPorts = [ 3000 ];
  
  # Optional: Create a systemd service to set up the environment file
  systemd.services.openhands-setup = {
    description = "Setup OpenHands environment";
    wantedBy = [ "multi-user.target" ];
    before = [ "openhands.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/openhands
      if [ ! -f /var/lib/openhands/secrets.env ]; then
        echo "Creating example secrets.env file"
        cat > /var/lib/openhands/secrets.env << EOF
LLM_API_KEY=your-api-key-here
# Add other environment variables as needed
EOF
        chmod 600 /var/lib/openhands/secrets.env
        chown openhands:openhands /var/lib/openhands/secrets.env
      fi
    '';
  };
}