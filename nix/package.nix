{ lib, pkgs, system, src }:

let
  python = pkgs.python312;
  
  # Create a Python environment with all dependencies
  pythonEnv = python.withPackages (ps: with ps; [
    # Core dependencies
    aiohttp
    boto3
    fastapi
    jinja2
    numpy
    pexpect
    pip
    poetry-core
    protobuf
    pydantic
    python-dotenv
    python-multipart
    tenacity
    toml
    types-toml
    uvicorn
    
    # LLM dependencies
    litellm
    openai
    anthropic
    
    # Browser dependencies
    html2text
    beautifulsoup4
    
    # Runtime dependencies
    jupyterlab
    notebook
    ipython
    
    # Additional dependencies
    termcolor
    psutil
    prompt-toolkit
    rich
    typer
    
    # Development dependencies
    pytest
    pytest-asyncio
    mypy
    ruff
    
    # Additional packages that might be needed
    requests
    websockets
    httpx
    typing-extensions
    pyyaml
  ]);
  
  # Frontend build dependencies
  nodeDeps = with pkgs; [
    nodejs_20
    nodePackages.npm
  ];
  
  # Runtime dependencies
  runtimeDeps = with pkgs; [
    tmux
    chromium
  ];
in
pkgs.stdenv.mkDerivation {
  pname = "openhands";
  version = "0.39.1";
  inherit src;
  
  buildInputs = [ pythonEnv ] ++ nodeDeps ++ runtimeDeps;
  nativeBuildInputs = with pkgs; [ makeWrapper wrapGAppsHook ];
  
  # Disable some phases that are not needed
  dontConfigure = true;
  
  # Build both backend and frontend
  buildPhase = ''
    # Set HOME for npm and other environment variables
    export HOME=$TMPDIR
    export CI=true
    export NODE_OPTIONS="--max-old-space-size=4096"
    
    echo "Building frontend..."
    if [ -d frontend ]; then
      cd frontend
      
      # Print npm and node versions for debugging
      echo "Node version: $(node --version)"
      echo "NPM version: $(npm --version)"
      
      # Try to build the frontend, but don't fail the build if it fails
      echo "Installing npm dependencies..."
      npm install --no-audit --no-fund --loglevel verbose || echo "Frontend dependency installation failed, continuing anyway"
      
      echo "Building frontend application..."
      npm run build --verbose || echo "Frontend build failed, continuing anyway"
      
      cd ..
    else
      echo "Frontend directory not found, skipping frontend build"
    fi
    
    echo "Installing Python package..."
    # Use pip to install the package in development mode
    pip install -e .
  '';
  
  # Install the package
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib/openhands
    mkdir -p $out/share/openhands
    mkdir -p $out/share/openhands/frontend
    
    # Copy the Python package
    cp -r openhands $out/lib/openhands/
    cp pyproject.toml poetry.lock $out/lib/openhands/
    
    # Copy the frontend build if it exists, otherwise create a minimal placeholder
    if [ -d frontend/build ]; then
      echo "Copying frontend build..."
      cp -r frontend/build/* $out/share/openhands/frontend/
    else
      echo "Frontend build not found, creating minimal placeholder..."
      cat > $out/share/openhands/frontend/index.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>OpenHands</title>
  <style>
    body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
    h1 { color: #333; }
    p { color: #666; }
  </style>
</head>
<body>
  <h1>OpenHands</h1>
  <p>Frontend not built. Please use the CLI interface or build the frontend manually.</p>
</body>
</html>
EOF
    fi
    
    # Create a wrapper script for CLI mode
    makeWrapper ${pythonEnv.interpreter} $out/bin/openhands \
      --add-flags "-m openhands.cli.main" \
      --set PYTHONPATH "$out/lib/openhands:$PYTHONPATH" \
      --set OPENHANDS_FRONTEND_PATH "$out/share/openhands/frontend" \
      --prefix PATH : "${pkgs.lib.makeBinPath runtimeDeps}"
    
    # Create a server wrapper script for web UI mode
    makeWrapper ${pythonEnv.interpreter} $out/bin/openhands-server \
      --add-flags "-m openhands.server.main" \
      --set PYTHONPATH "$out/lib/openhands:$PYTHONPATH" \
      --set OPENHANDS_FRONTEND_PATH "$out/share/openhands/frontend" \
      --prefix PATH : "${pkgs.lib.makeBinPath runtimeDeps}"
  '';
  
  # Fix rpaths for libraries
  postFixup = ''
    wrapProgram $out/bin/openhands \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath runtimeDeps}"
    
    wrapProgram $out/bin/openhands-server \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath runtimeDeps}"
  '';
  
  meta = with lib; {
    description = "OpenHands: Code Less, Make More - AI software engineer";
    homepage = "https://github.com/all-hands-dev/OpenHands";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [];
  };
}