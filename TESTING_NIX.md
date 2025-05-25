# 测试和调整 Nix Flake

本文档提供了测试和调整 OpenHands Nix Flake 的步骤。

## 初次构建测试

首次尝试构建 flake 时，您可能会遇到一些错误，这是正常的。以下是处理这些错误的步骤：

### 1. 获取 npmDepsHash

首次构建前端包时，Nix 会报错并提供正确的哈希值：

```bash
nix build .#openhandsPackage
```

您会看到类似这样的错误：

```
error: hash mismatch in fixed-output derivation '/nix/store/...':
  wanted: sha256:pkgs.lib.fakeHash
  got:    sha256:abcdef1234567890...
```

使用提供的哈希值更新 flake.nix 中的 `npmDepsHash`：

```nix
npmDepsHash = "sha256:abcdef1234567890...";  # 使用实际的哈希值
```

### 2. 处理 Python 依赖问题

如果构建过程中遇到 Python 依赖问题，您需要在 `poetryOverrides` 部分添加相应的覆盖：

```nix
poetryOverrides = pkgs.poetry2nix.overrides.withDefaults (final: prev: {
  # 添加有问题的包的覆盖
  problematic-package = prev.problematic-package.overridePythonAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ final.setuptools ];
  });
});
```

### 3. 测试开发环境

测试开发环境是否正常工作：

```bash
nix develop
make build
make run
```

## 常见问题和解决方案

### 前端构建问题

如果前端构建失败，可能需要调整 `frontendBuild` 部分：

```nix
buildPhase = ''
  export HOME=$(mktemp -d)
  npm ci  # 使用 ci 而不是 install
  npm run build
'';
```

### Python 依赖问题

对于特定的 Python 包问题，可以尝试以下解决方案：

1. 使用 `pkgs.fetchPypi` 获取特定版本
2. 添加缺失的构建依赖
3. 禁用特定的测试

例如：

```nix
browsergym-core = prev.browsergym-core.overridePythonAttrs (old: {
  buildInputs = (old.buildInputs or [ ]) ++ [ final.setuptools final.wheel ];
  doCheck = false;  # 禁用测试
});
```

### 系统依赖问题

确保在 `propagatedBuildInputs` 中包含所有必要的系统依赖：

```nix
propagatedBuildInputs = with pkgs; [
  # 添加缺失的系统依赖
  libffi
  openssl
  # ...其他依赖
];
```

## 测试 NixOS 模块

在 NixOS 系统上测试模块：

1. 创建一个测试配置文件 `test-openhands.nix`：

```nix
{ pkgs, ... }:
{
  imports = [ ./nixos-configuration.nix ];
  
  # 添加测试特定的配置
  services.openhands = {
    enable = true;
    host = "127.0.0.1";
    port = 3000;
  };
}
```

2. 使用 `nixos-rebuild` 测试配置：

```bash
sudo nixos-rebuild test -I nixos-config=./test-openhands.nix
```

3. 检查服务是否正常运行：

```bash
systemctl status openhands
```

## 发布前的最终检查

在发布 flake 之前，请确保：

1. 所有哈希值都已更新为实际值
2. 所有依赖问题都已解决
3. 开发环境和包都能正常构建
4. NixOS 模块已经过测试
5. 文档已更新并准确