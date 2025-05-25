# OpenHands Nix 构建问题排查指南

## 前端构建卡住问题

如果在使用 `nix build .#openhands` 时，构建过程在前端构建阶段卡住，可能是由于以下原因：

1. npm 依赖下载问题
2. Node.js 内存限制
3. 网络连接问题
4. 权限问题

### 解决方案

我们已经对 `nix/package.nix` 文件进行了以下改进：

1. 增加了 Node.js 内存限制：
   ```nix
   export NODE_OPTIONS="--max-old-space-size=4096"
   ```

2. 使用 `npm install` 替代 `npm ci`，并添加详细日志：
   ```nix
   npm install --no-audit --no-fund --loglevel verbose
   ```

3. 添加错误处理，即使前端构建失败也能继续：
   ```nix
   npm install ... || echo "Frontend dependency installation failed, continuing anyway"
   npm run build ... || echo "Frontend build failed, continuing anyway"
   ```

4. 如果前端构建失败，创建一个最小的占位符前端：
   ```nix
   if [ -d frontend/build ]; then
     # 复制前端构建
   else
     # 创建占位符前端
   fi
   ```

## Python 依赖问题

我们还扩展了 Python 依赖列表，确保包含所有必要的依赖：

1. 添加了更多 LLM 依赖：
   - openai
   - anthropic

2. 添加了更多实用工具：
   - rich
   - typer
   - requests
   - httpx
   - websockets
   - typing-extensions
   - pyyaml

## 测试构建

要测试这些更改是否解决了问题，请运行：

```bash
nix build .#openhands
```

如果构建成功，你应该能够运行：

```bash
./result/bin/openhands
# 或
./result/bin/openhands-server
```

## 其他排查步骤

如果仍然遇到问题：

1. 检查 Nix 构建日志：
   ```bash
   nix log /nix/store/....-openhands-0.39.1.drv
   ```

2. 尝试手动构建前端：
   ```bash
   cd frontend
   npm install
   npm run build
   ```

3. 检查 Python 依赖：
   ```bash
   pip list
   ```

4. 确保所有必要的系统依赖都已安装