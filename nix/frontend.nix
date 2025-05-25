{ pkgs, src }:

pkgs.buildNpmPackage {
  pname = "openhands-frontend";
  version = "0.39.1";
  
  # 使用完整仓库作为源，但只构建前端部分
  inherit src;
  
  # 在 postPatch 阶段复制前端文件到根目录
  postPatch = ''
    cp -r frontend/* ./
    cp frontend/.* ./ 2>/dev/null || true
  '';
  
  # 使用 package-lock.json 确保依赖的确定性
  npmDepsHash = "sha256-uymMFsCID2rQXtmh5SQxmiiFlZjN1HxPyC2UXnDzcSw=";
  
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