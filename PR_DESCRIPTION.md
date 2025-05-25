# 修复 Nix 构建问题

## 问题描述

在使用 `nix build .#openhands` 命令构建 OpenHands 包时，构建过程在前端构建阶段卡住，没有任何进展。此外，Python 包构建也存在依赖问题。

## 解决方案

1. 完全重构了前端构建过程：
   - 使用 `pkgs.buildNpmPackage` 替代手动 npm 命令
   - 修复了前端目录结构处理
   - 使用 package-lock.json 哈希值确保确定性构建
   - 正确处理前端资源文件

2. 简化了 Python 包处理：
   - 使用 `withPackages` 替代 `buildPythonPackage` 避免依赖问题
   - 扩展了 Python 依赖列表，确保包含所有必要的依赖
   - 修复了 PYTHONPATH 设置

3. 改进了包装脚本：
   - 修复了环境变量设置
   - 添加了正确的运行时依赖
   - 确保前端路径正确设置

## 测试

这些更改已经在本地测试，可以成功构建 OpenHands 包，包括前端和后端组件。测试了以下功能：

- 前端包单独构建 (`nix build .#openhands-frontend`)
- 完整包构建 (`nix build .#openhands`)
- CLI 模式和服务器模式

## 相关问题

这解决了用户在使用 Nix 构建 OpenHands 包时遇到的前端构建卡住问题和 Python 依赖问题。现在用户可以使用 Nix 轻松构建和安装 OpenHands。