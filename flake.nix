{
  description = "OpenHands: Code Less, Make More - AI software engineer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # List of supported systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      # Helper function to generate attributes for all supported systems
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Helper function to get nixpkgs for a specific system
      nixpkgsFor = system: import nixpkgs { inherit system; };
    in {
      # Packages
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor system;
        in {
          default = pkgs.hello;  # Placeholder for actual package
          openhands = pkgs.hello;  # Placeholder for actual package
        }
      );
      
      # Development shells
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor system;
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              python312
              poetry
              nodejs_20
              nodePackages.npm
              pre-commit
              tmux
              chromium
            ];
            
            shellHook = ''
              echo "OpenHands development environment"
              echo "Run 'make build' to build the project"
              echo "Run 'make run' to start the application"
            '';
          };
        }
      );
      
      # NixOS module
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.openhands;
        in {
          options.services.openhands = {
            enable = lib.mkEnableOption "OpenHands AI software engineer";
            
            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.hello;  # Placeholder for actual package
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
            
            systemd.services.openhands = {
              description = "OpenHands AI software engineer";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              
              serviceConfig = {
                User = cfg.user;
                Group = cfg.group;
                ExecStart = "${cfg.package}/bin/hello";  # Placeholder for actual command
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
                # Create workspace directory if it doesn't exist
                mkdir -p ${cfg.workspaceDir}
                
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
        };
    };
}