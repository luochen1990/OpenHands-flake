# 测试 OpenHands Nix 包

本文档提供了测试 OpenHands Nix 包的指南。

## 先决条件

- 安装了 Nix 并启用了 flakes 功能
- Git

## 测试步骤

1. 克隆仓库：

```bash
git clone https://github.com/luochen1990/OpenHands-flake.git
cd OpenHands-flake
```

2. 切换到 `fix-package-build` 分支：

```bash
git checkout fix-package-build
```

3. 构建包：

```bash
# 构建默认包
nix build

# 或者明确指定包
nix build .#openhands
```

4. 测试开发环境：

```bash
nix develop
```

5. 测试 NixOS 模块（需要 NixOS 系统）：

```bash
# 创建一个测试配置
cat > test-config.nix << EOF
{ pkgs, ... }:
{
  imports = [ ./nix/nixosModule.nix ];
  
  services.openhands = {
    enable = true;
    port = 3000;
    host = "127.0.0.1";
    llmModel = "gpt-4o";
  };
}
EOF

# 构建测试配置
nix-build -E 'with import <nixpkgs> {}; (pkgs.nixos test-config.nix).config.system.build.toplevel'
```

## 测试前端构建

为了专门测试前端构建，可以使用以下命令：

```bash
# 测试前端构建
nix build .#openhands-frontend

# 检查前端构建结果
ls -la result/
```

这将使用 `pkgs.buildNpmPackage` 构建前端，并将结果放在 `result` 目录中。如果构建成功，应该能看到前端的构建输出，包括 index.html 和相关的 JavaScript 文件。

## 调试 buildNpmPackage

如果前端构建失败，可以使用以下方法进行调试：

1. **查看构建日志**：

```bash
nix build .#openhands-frontend --show-trace
```

2. **检查 npmDepsHash**：确保 npmDepsHash 是正确的。如果不确定，可以先使用一个假的哈希值（如 `pkgs.lib.fakeSha256`），Nix 会告诉你正确的哈希值：

```nix
npmDepsHash = pkgs.lib.fakeSha256;
```

构建失败时，Nix 会显示类似以下的错误：

```
hash mismatch in fixed-output derivation '/nix/store/...':
  wanted: sha256:0000000000000000000000000000000000000000000000000000
  got:    sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234
```

然后，你可以使用 Nix 提供的正确哈希值更新 npmDepsHash。

3. **检查 sourceRoot**：确保 sourceRoot 指向正确的前端目录：

```nix
sourceRoot = "${src.name}/frontend";
```

4. **检查 npmFlags**：如果需要特殊的 npm 标志，确保它们被正确设置：

```nix
npmFlags = ["--legacy-peer-deps"];
```

## 常见问题

### 前端构建问题

如果前端构建失败，可能是由于以下原因：

1. **npmDepsHash 不正确**：如果修改了 package-lock.json，需要更新 npmDepsHash。可以使用以下命令计算新的哈希值：

```bash
nix-hash --type sha256 --flat frontend/package-lock.json
```

或者让 Nix 告诉你正确的哈希值，如上所述。

2. **Node.js 版本不兼容**：确保使用的 Node.js 版本与项目兼容。我们使用的是 Node.js 20。

3. **内存不足**：前端构建可能需要大量内存。可以通过设置 NODE_OPTIONS 环境变量来增加可用内存：

```bash
export NODE_OPTIONS="--max-old-space-size=4096"
```

4. **依赖问题**：如果有依赖问题，可能需要修改 npmFlags：

```nix
npmFlags = ["--legacy-peer-deps" "--no-audit" "--no-fund"];
```

### Python 依赖问题

如果 Python 依赖构建失败，可能需要添加或修改依赖。可以编辑 `nix/package.nix` 文件中的 `pythonEnv` 定义。

## 验证构建结果

构建成功后，可以通过以下方式验证结果：

1. 检查构建输出：

```bash
ls -la result/bin/
```

应该能看到 `openhands` 和 `openhands-server` 两个可执行文件。

2. 运行构建的程序：

```bash
./result/bin/openhands --help
```

这应该显示 OpenHands CLI 的帮助信息。

3. 检查前端文件：

```bash
ls -la result/share/openhands/frontend/
```

应该能看到构建好的前端文件，包括 index.html 和相关的 JavaScript 文件。

## 验证 Nix 构建的可复现性

Nix 的一个重要特性是构建的可复现性。要验证这一点，可以多次构建包并比较结果：

```bash
# 清理之前的构建结果
rm -rf result

# 第一次构建
nix build .#openhands
cp -r result result1

# 清理
rm -rf result

# 第二次构建
nix build .#openhands
cp -r result result2

# 比较两次构建结果
diff -r result1 result2
```

如果构建是可复现的，diff 命令应该不会显示任何差异。