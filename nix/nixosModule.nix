{ config, lib, pkgs, openhandsPkg, ... }:

let
  cfg = config.services.openhands;
in {
  options.services.openhands = {
    enable = lib.mkEnableOption "OpenHands AI software engineer";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = openhandsPkg;
      description = "The OpenHands package to use.";
    };
    
    user = lib.mkOption {
      type = lib.types.str;
      default = "openhands";
      description = "User account under which OpenHands runs.";
    };
    
    group = lib.mkOption {
      type = lib.types.str;
      default = "openhands";
      description = "Group under which OpenHands runs.";
    };
    
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/openhands";
      description = "Directory to store OpenHands data.";
    };
    
    workspaceDir = lib.mkOption {
      type = lib.types.path;
      default = "${cfg.dataDir}/workspace";
      description = "Directory to store OpenHands workspaces.";
    };
    
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port on which OpenHands server will listen.";
    };
    
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host on which OpenHands server will listen.";
    };
    
    llmApiKey = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "API key for the LLM service.";
    };
    
    llmModel = lib.mkOption {
      type = lib.types.str;
      default = "gpt-4o";
      description = "LLM model to use.";
    };
    
    llmBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Base URL for the LLM service (for local LLMs).";
    };
    
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Environment file containing sensitive configuration.";
    };
    
    serverMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to run OpenHands in server mode (with web UI).";
    };
  };
  
  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = lib.mkIf (cfg.user == "openhands") {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      description = "OpenHands service user";
    };
    
    users.groups.${cfg.group} = lib.mkIf (cfg.group == "openhands") {};
    
    # Create a separate setup service to ensure directories exist
    systemd.services.openhands-setup = lib.mkIf (cfg.user == "openhands") {
      description = "Setup for OpenHands service";
      wantedBy = [ "multi-user.target" ];
      before = [ "openhands.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Group = "root";
      };
      
      script = ''
        # Create data directory if it doesn't exist
        mkdir -p ${cfg.dataDir}
        chown ${cfg.user}:${cfg.group} ${cfg.dataDir}
        
        # Create workspace directory if it doesn't exist
        mkdir -p ${cfg.workspaceDir}
        chown ${cfg.user}:${cfg.group} ${cfg.workspaceDir}
        
        # Create environment file if specified but doesn't exist
        ${lib.optionalString (cfg.environmentFile != null) ''
          ENV_FILE="${cfg.environmentFile}"
          ENV_DIR=$(dirname "$ENV_FILE")
          
          # Create directory for environment file if it doesn't exist
          if [ ! -d "$ENV_DIR" ]; then
            mkdir -p "$ENV_DIR"
          fi
          
          # Create empty environment file if it doesn't exist
          if [ ! -f "$ENV_FILE" ]; then
            touch "$ENV_FILE"
            echo "# OpenHands environment file" > "$ENV_FILE"
            ${lib.optionalString (cfg.llmApiKey != "") ''
              echo "LLM_API_KEY=${cfg.llmApiKey}" >> "$ENV_FILE"
            ''}
            chown ${cfg.user}:${cfg.group} "$ENV_FILE"
            chmod 600 "$ENV_FILE"
          fi
        ''}
      '';
    };
    
    # The main OpenHands service
    systemd.services.openhands = {
      description = "OpenHands AI software engineer";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ lib.optional (cfg.user == "openhands") "openhands-setup.service";
      requires = lib.optional (cfg.user == "openhands") "openhands-setup.service";
      
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStart = if cfg.serverMode 
          then "${cfg.package}/bin/openhands-server"
          else "${cfg.package}/bin/openhands";
        WorkingDirectory = cfg.dataDir;
        StateDirectory = lib.removePrefix "/var/lib/" cfg.dataDir;
        Restart = "on-failure";
        RestartSec = "5s";
      } // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };
      
      environment = {
        BACKEND_HOST = cfg.host;
        BACKEND_PORT = toString cfg.port;
        WORKSPACE_BASE = cfg.workspaceDir;
        SERVE_FRONTEND = "true";
      } // lib.optionalAttrs (cfg.llmApiKey != "") {
        LLM_API_KEY = cfg.llmApiKey;
      } // lib.optionalAttrs (cfg.llmModel != "") {
        LLM_MODEL = cfg.llmModel;
      } // lib.optionalAttrs (cfg.llmBaseUrl != "") {
        LLM_BASE_URL = cfg.llmBaseUrl;
      };
      
      preStart = ''
        # Create basic config.toml if it doesn't exist
        if [ ! -f ${cfg.dataDir}/config.toml ]; then
          cat > ${cfg.dataDir}/config.toml << EOF
        [core]
        workspace_base="${cfg.workspaceDir}"

        [llm]
        model="${cfg.llmModel}"
        EOF
          # Add API key if provided
          ${lib.optionalString (cfg.llmApiKey != "") ''
            echo 'api_key="${cfg.llmApiKey}"' >> ${cfg.dataDir}/config.toml
          ''}
          # Add base URL if provided
          ${lib.optionalString (cfg.llmBaseUrl != "") ''
            echo 'base_url="${cfg.llmBaseUrl}"' >> ${cfg.dataDir}/config.toml
          ''}
        fi
      '';
    };
  };
}