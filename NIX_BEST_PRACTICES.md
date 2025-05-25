# OpenHands Nix 打包最佳实践

本文档解释了我们如何按照 Nix 的最佳实践来打包 OpenHands 项目。

## Nix 的核心哲学

Nix 的核心哲学包括：

1. **确定性构建**：相同的输入应该总是产生相同的输出
2. **可复现性**：任何人在任何时间都应该能够重现相同的构建结果
3. **隔离性**：构建过程应该与系统的其余部分隔离
4. **声明性**：构建过程应该以声明性方式描述，而不是命令式

## JavaScript/Node.js 项目的 Nix 最佳实践

对于 JavaScript/Node.js 项目，Nix 提供了专门的构建函数：

1. `pkgs.buildNpmPackage`：用于使用 npm 构建 Node.js 项目
2. `pkgs.mkYarnPackage`：用于使用 Yarn 构建 Node.js 项目

这些函数提供了以下优势：

- 自动处理 Node.js 依赖的获取和缓存
- 确保依赖的确定性（通过 package-lock.json 或 yarn.lock）
- 提供隔离的构建环境
- 处理 Node.js 项目的特定需求

## OpenHands 前端打包

我们使用 `pkgs.buildNpmPackage` 来构建 OpenHands 的前端部分：

```nix
pkgs.buildNpmPackage {
  pname = "openhands-frontend";
  version = "0.39.1";
  
  # 使用完整仓库作为源，但只构建前端部分
  inherit src;
  
  # 指定前端目录
  sourceRoot = "${src.name}/frontend";
  
  # 使用 package-lock.json 确保依赖的确定性
  npmDepsHash = "sha256-uaxHdLMsYWvXbZvXdm+vXrYa+vfX5DYoO2izIuOLjzM=";
  
  # 构建命令
  buildPhase = ''
    export HOME=$TMPDIR
    export CI=true
    export NODE_OPTIONS="--max-old-space-size=4096"
    
    npm run build
  '';
  
  # 安装命令
  installPhase = ''
    mkdir -p $out
    cp -r build/* $out/
  '';
  
  # 使用 npm ci 而不是 npm install
  npmFlags = ["--legacy-peer-deps"];
  
  # 元数据
  meta = with pkgs.lib; {
    description = "Frontend for OpenHands AI software engineer";
    homepage = "https://github.com/all-hands-dev/OpenHands";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [];
  };
}
```

关键点：

1. **npmDepsHash**：这是 package-lock.json 文件的哈希值，确保依赖的确定性
2. **sourceRoot**：指定前端代码的位置
3. **npmFlags**：提供额外的 npm 标志，如 `--legacy-peer-deps`
4. **构建和安装阶段**：明确定义构建和安装步骤

## 与之前方法的比较

之前的方法存在以下问题：

1. **非确定性**：直接在 shell 中调用 npm 可能导致非确定性结果
2. **错误处理不当**：允许构建失败并提供降级方案违背了 Nix 的确定性原则
3. **依赖管理不佳**：没有利用 Nix 的依赖管理功能

新方法解决了这些问题：

1. **确定性**：使用 npmDepsHash 确保依赖的确定性
2. **正确的错误处理**：如果构建失败，整个构建应该失败，而不是提供降级方案
3. **更好的依赖管理**：利用 Nix 的依赖管理功能

## 结论

通过使用 `pkgs.buildNpmPackage`，我们遵循了 Nix 的最佳实践，确保了构建的确定性和可复现性。这种方法更符合 Nix 的哲学，提供了更可靠的构建结果。