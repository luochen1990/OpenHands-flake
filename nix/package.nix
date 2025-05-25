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
    
    # Browser dependencies
    html2text
    
    # Runtime dependencies
    jupyterlab
    notebook
    
    # Additional dependencies
    termcolor
    psutil
    prompt-toolkit
    
    # Development dependencies
    pytest
    pytest-asyncio
    mypy
    ruff
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
    # Set HOME for npm
    export HOME=$TMPDIR
    
    echo "Building frontend..."
    cd frontend
    npm ci
    npm run build
    cd ..
    
    echo "Installing Python package..."
    # Use pip to install the package in development mode
    pip install -e .
  '';
  
  # Install the package
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib/openhands
    mkdir -p $out/share/openhands
    
    # Copy the Python package
    cp -r openhands $out/lib/openhands/
    cp pyproject.toml poetry.lock $out/lib/openhands/
    
    # Copy the frontend build
    cp -r frontend/build $out/share/openhands/frontend
    
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