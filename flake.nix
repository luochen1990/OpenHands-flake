{
  description = "OpenHands: Code Less, Make More - AI software engineer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, poetry2nix, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ poetry2nix.overlays.default ];
          };

          # Python version used by the project
          python = pkgs.python312;

          # Override packages that might have issues with poetry2nix
          poetryOverrides = pkgs.poetry2nix.overrides.withDefaults (final: prev: {
            # Add overrides for problematic packages here if needed
            browsergym-core = prev.browsergym-core.overridePythonAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ final.setuptools ];
            });
            
            e2b = prev.e2b.overridePythonAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ final.setuptools ];
            });
            
            # Add more overrides as needed
          });

          # Create a Python environment with all dependencies
          poetryEnv = pkgs.poetry2nix.mkPoetryEnv {
            projectDir = self;
            python = python;
            overrides = poetryOverrides;
            editablePackageSources = {
              openhands-ai = self;
            };
          };

          # Build the frontend
          frontendBuild = pkgs.buildNpmPackage {
            pname = "openhands-frontend";
            version = "0.39.1";
            src = "${self}/frontend";
            
            npmDepsHash = pkgs.lib.fakeHash;  # Replace with actual hash after first build attempt
            
            buildInputs = with pkgs; [
              nodejs_20
            ];
            
            buildPhase = ''
              export HOME=$(mktemp -d)
              npm run build
            '';
            
            installPhase = ''
              mkdir -p $out
              cp -r build/* $out/
            '';
          };

          # The main package
          openhandsPackage = pkgs.poetry2nix.mkPoetryApplication {
            projectDir = self;
            python = python;
            overrides = poetryOverrides;
            
            # Propagate build inputs to the application
            propagatedBuildInputs = with pkgs; [
              # System dependencies
              tmux
              nodejs_20
              
              # For browser functionality
              chromium
              
              # For terminal functionality
              bash
              coreutils
              findutils
              gnugrep
              gnused
            ];
            
            postInstall = ''
              # Create the frontend directory
              mkdir -p $out/lib/python3.12/site-packages/frontend/build
              
              # Copy the frontend build
              cp -r ${frontendBuild}/* $out/lib/python3.12/site-packages/frontend/build/
              
              # Create a wrapper script
              mkdir -p $out/bin
              cat > $out/bin/openhands-server << EOF
              #!/bin/sh
              export SERVE_FRONTEND=true
              exec $out/bin/openhands server "\$@"
              EOF
              chmod +x $out/bin/openhands-server
            '';
          };
        in {
          default = openhandsPackage;
          openhands = openhandsPackage;
        };
      
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ poetry2nix.overlays.default ];
          };
          
          # Python version used by the project
          python = pkgs.python312;
          
          # Override packages that might have issues with poetry2nix
          poetryOverrides = pkgs.poetry2nix.overrides.withDefaults (final: prev: {
            # Add overrides for problematic packages here if needed
            browsergym-core = prev.browsergym-core.overridePythonAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ final.setuptools ];
            });
            
            e2b = prev.e2b.overridePythonAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ final.setuptools ];
            });
          });
          
          # Create a Python environment with all dependencies
          poetryEnv = pkgs.poetry2nix.mkPoetryEnv {
            projectDir = self;
            python = python;
            overrides = poetryOverrides;
            editablePackageSources = {
              openhands-ai = self;
            };
          };
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Python environment with all dependencies
              poetryEnv
              poetry
              
              # Node.js and npm for frontend development
              nodejs_20
              nodePackages.npm
              
              # Development tools
              pre-commit
              
              # System dependencies
              tmux
              
              # For browser functionality
              chromium
              
              # For terminal functionality
              bash
              coreutils
              findutils
              gnugrep
              gnused
            ];
            
            shellHook = ''
              echo "OpenHands development environment"
              echo "Run 'make build' to build the project"
              echo "Run 'make run' to start the application"
            '';
          };
        }
      );
      # NixOS module for the OpenHands service
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.openhands;
        in {
          options.services.openhands = {
            enable = lib.mkEnableOption "OpenHands AI software engineer";
            
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.system}.openhands;
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
                ExecStart = "${cfg.package}/bin/openhands-server";
                WorkingDirectory = cfg.dataDir;
                StateDirectory = lib.removePrefix "/var/lib/" cfg.dataDir;
                EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
                Restart = "on-failure";
                RestartSec = "5s";
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