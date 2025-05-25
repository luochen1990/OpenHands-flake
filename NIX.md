# OpenHands Nix Integration

This document explains how to use OpenHands with Nix and NixOS.

## Using the Flake

OpenHands provides a Nix flake that offers:

1. A package for installing OpenHands
2. A development shell for working on OpenHands
3. A NixOS module for running OpenHands as a service

### Prerequisites

- Nix with flakes enabled
- For development: Git, Node.js (v20+), and Python 3.12

## Installation

### As a Package

To install OpenHands using the flake:

```bash
nix profile install github:luochen1990/OpenHands-flake
```

This will make the `openhands` command available in your environment.

### Development Shell

To enter a development shell with all dependencies:

```bash
nix develop github:luochen1990/OpenHands-flake
```

This provides a complete development environment with all required dependencies.

Inside the development shell, you can:

```bash
# Build the project
make build

# Run the application
make run
```

## NixOS Module

OpenHands can be deployed as a service on NixOS. Add the following to your NixOS configuration:

```nix
{
  inputs.openhands.url = "github:luochen1990/OpenHands-flake";
  
  outputs = { self, nixpkgs, openhands, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      # ...
      modules = [
        openhands.nixosModules.default
        {
          services.openhands = {
            enable = true;
            host = "0.0.0.0";  # Listen on all interfaces
            port = 3000;
            llmModel = "gpt-4o";
            # For sensitive information, use environmentFile
            environmentFile = "/path/to/openhands.env";
          };
        }
      ];
    };
  };
}
```

For a more complete example, see the [examples/nixos-configuration.nix](examples/nixos-configuration.nix) file.

### Home Manager

If you prefer using Home Manager, you can also integrate OpenHands there:

```nix
{
  imports = [
    # Import the example configuration
    (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/luochen1990/OpenHands-flake/main/examples/home-manager.nix";
      sha256 = "..."; # Replace with the actual hash
    })
  ];
}
```

See the [examples/home-manager.nix](examples/home-manager.nix) file for details.

### Environment File

For sensitive information like API keys, create an environment file:

```
LLM_API_KEY=your-api-key-here
```

**重要提示**：当使用默认的 `user = "openhands"` 设置时，模块会自动创建一个名为 `openhands-setup` 的服务，该服务会：

1. 确保数据目录和工作区目录存在
2. 设置正确的所有权和权限
3. 如果指定了 `environmentFile` 但文件不存在，则创建一个空的环境文件

如果您使用自定义用户而不是默认的 "openhands" 用户，您需要确保：

1. 数据目录和工作区目录存在并且具有正确的权限
2. 如果指定了环境文件，该文件必须存在并且可以被服务访问

如果您不需要使用环境文件，请不要设置 `environmentFile` 选项，或将其设置为 `null`：

```nix
services.openhands = {
  enable = true;
  # 不要设置 environmentFile 选项
  # 或者明确设置为 null
  environmentFile = null;
};
```

### Configuration Options

The NixOS module provides the following options:

| Option | Description | Default |
|--------|-------------|---------|
| `enable` | Enable the OpenHands service | `false` |
| `package` | The OpenHands package to use | `openhands` from the flake |
| `user` | User account under which OpenHands runs | `"openhands"` |
| `group` | Group under which OpenHands runs | `"openhands"` |
| `dataDir` | Directory to store OpenHands data | `"/var/lib/openhands"` |
| `workspaceDir` | Directory to store OpenHands workspaces | `"${dataDir}/workspace"` |
| `port` | Port on which OpenHands server will listen | `3000` |
| `host` | Host on which OpenHands server will listen | `"127.0.0.1"` |
| `llmApiKey` | API key for the LLM service | `""` |
| `llmModel` | LLM model to use | `"gpt-4o"` |
| `llmBaseUrl` | Base URL for the LLM service (for local LLMs) | `""` |
| `environmentFile` | Environment file containing sensitive configuration | `null` |
| `serverMode` | Whether to run OpenHands in server mode (with web UI) | `true` |

## Implementation Details

The OpenHands Nix integration is structured as follows:

### Package Structure

The package implementation is modularized into separate files:

- `nix/package.nix`: Defines the OpenHands package
- `nix/devShell.nix`: Defines the development environment
- `nix/nixosModule.nix`: Defines the NixOS module

This modular approach makes it easier to maintain and extend the Nix integration.

### Server Mode vs CLI Mode

The NixOS module supports running OpenHands in two modes:

1. **Server Mode** (default): Runs OpenHands with a web UI
2. **CLI Mode**: Runs OpenHands in command-line mode

You can control this with the `serverMode` option:

```nix
services.openhands = {
  enable = true;
  serverMode = true;  # Set to false for CLI mode
};
```

### Python Environment

The package includes a Python environment with all required dependencies. This environment is created using `python.withPackages` to ensure all dependencies are available.

### Frontend Build

The frontend is built during the package build process using Node.js and npm. The build artifacts are then included in the final package.

## Troubleshooting

### Frontend Build Issues

If you encounter issues with the frontend build, check the following:

1. Make sure Node.js and npm are available
2. Check for any errors in the build logs
3. Try building the frontend manually to identify any issues

### Python Dependencies

If certain Python packages fail to build, you may need to add specific overrides in the `nix/package.nix` file. Common issues include:

1. Missing build dependencies
2. Incompatible package versions
3. Platform-specific issues

### Service Startup Issues

Check the service logs with:

```bash
journalctl -u openhands.service -f
```

Common issues include:

1. Missing or incorrect permissions on data directories
2. Environment file issues
3. Network configuration problems

Make sure the service has the correct permissions to access the data directory and workspace.