# 添加 OpenHands 的 Nix 集成

## 概述

本拉取请求为 OpenHands 项目添加了完整的 Nix 集成，包括 Nix 包、开发环境和 NixOS 模块。这使得用户可以使用 Nix 轻松地安装和运行 OpenHands，无论是作为开发环境还是生产服务。

## 主要特性

1. **Nix 包**：提供了 OpenHands 的可安装包，包含前端和后端组件
2. **开发环境**：提供了一个完整的开发环境，包含所有必要的工具和依赖
3. **NixOS 模块**：提供了一个 NixOS 服务模块，支持灵活的配置选项
4. **文档和示例**：提供了详细的文档和示例配置，帮助用户快速上手

## 实现细节

- 使用模块化设计，将不同的功能分离到不同的文件中
- 前端使用 `buildNpmPackage` 进行构建，确保构建过程的可重现性
- 后端使用 `python.withPackages` 创建 Python 环境，包含所有必要的依赖
- NixOS 模块提供了灵活的配置选项，支持 CLI 模式和服务器模式
- 支持环境文件，用于存储敏感信息如 API 密钥
- 自动创建必要的目录和文件，简化用户配置

## 解决的问题

1. 修复了前端构建卡住问题：
   - 使用 `pkgs.buildNpmPackage` 替代手动 npm 命令
   - 修复了前端目录结构处理
   - 使用 package-lock.json 哈希值确保确定性构建

2. 解决了 Python 依赖问题：
   - 使用 `withPackages` 替代 `buildPythonPackage` 避免依赖问题
   - 扩展了 Python 依赖列表，确保包含所有必要的依赖
   - 修复了 PYTHONPATH 设置

3. 改进了 NixOS 模块：
   - 添加了环境文件处理
   - 添加了服务器模式选项
   - 修复了目录和文件权限问题

## 测试

所有组件都已经过测试，包括：

1. 前端包构建 (`nix build .#openhands-frontend`)
2. 完整包构建 (`nix build .#openhands`)
3. 开发环境 (`nix develop`)
4. flake 检查 (`nix flake check`)

所有测试都成功通过，包可以正常构建和运行。

## 文档

- `NIX.md`：详细介绍了 Nix 集成的使用方法和配置选项
- `examples/`：包含 NixOS 和 Home Manager 的示例配置
- `SUMMARY.md`：总结了 Nix 集成的实现
- `COMMIT_MESSAGE.md`：提供了详细的提交信息

## 使用方法

### 安装 OpenHands

```bash
nix profile install github:luochen1990/OpenHands-flake
```

### 开发环境

```bash
nix develop github:luochen1990/OpenHands-flake
```

### NixOS 服务

```nix
{
  imports = [ 
    (builtins.fetchTarball "https://github.com/luochen1990/OpenHands-flake/archive/main.tar.gz").nixosModules.default 
  ];
  
  services.openhands = {
    enable = true;
    host = "0.0.0.0";
    port = 3000;
  };
}
```