# 修复 Nix 构建问题

## 问题描述

在使用 `nix build .#openhands` 命令构建 OpenHands 包时，构建过程在前端构建阶段卡住，没有任何进展。

## 解决方案

1. 改进了前端构建过程：
   - 增加了 Node.js 内存限制
   - 使用 `npm install` 替代 `npm ci`，并添加详细日志
   - 添加错误处理，即使前端构建失败也能继续
   - 如果前端构建失败，创建一个最小的占位符前端

2. 扩展了 Python 依赖列表，确保包含所有必要的依赖：
   - 添加了更多 LLM 依赖（openai, anthropic）
   - 添加了更多实用工具（rich, typer, requests, httpx 等）

3. 添加了 TROUBLESHOOTING.md 文件，提供排查构建问题的指南

## 测试

这些更改已经在本地测试，可以成功构建 OpenHands 包。即使前端构建失败，也能创建一个可用的包，用户可以使用 CLI 模式运行 OpenHands。

## 相关问题

这解决了用户在使用 Nix 构建 OpenHands 包时遇到的前端构建卡住问题。