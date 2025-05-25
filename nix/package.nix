{ lib, pkgs, system, src }:

let
  # Build frontend using proper Nix JavaScript packaging
  frontend = import ./frontend.nix {
    inherit pkgs src;
  };
  
  # Runtime dependencies
  runtimeDeps = with pkgs; [
    tmux
    chromium
  ];
  
  # Create a simple Python package that just wraps the OpenHands code
  # This is a simplified approach that avoids dependency issues
  pythonPackage = pkgs.python312.withPackages (ps: with ps; [
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
    
    # Additional packages that might be needed
    requests
    websockets
    httpx
    typing-extensions
    pyyaml
    
    # Missing dependencies from error message (only include those available in nixpkgs)
    minio
    pathspec
    poetry
    pyjwt
    python-socketio
    redis
    zope-interface
  ]);
in
pkgs.stdenv.mkDerivation {
  pname = "openhands";
  version = "0.39.1";
  inherit src;
  
  buildInputs = [ pythonPackage ] ++ runtimeDeps;
  nativeBuildInputs = with pkgs; [ makeWrapper wrapGAppsHook ];
  
  # Disable some phases that are not needed
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  
  # Install the package
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib/openhands
    mkdir -p $out/share/openhands/frontend
    
    # Copy the Python package
    cp -r $src/openhands $out/lib/openhands/
    
    # Copy the frontend build from the separate derivation
    echo "Copying frontend build..."
    cp -r ${frontend}/* $out/share/openhands/frontend/
    
    # Create a wrapper script for CLI mode
    makeWrapper ${pythonPackage}/bin/python $out/bin/openhands \
      --add-flags "-m openhands.cli.main" \
      --set PYTHONPATH "$out/lib:$PYTHONPATH" \
      --set OPENHANDS_FRONTEND_PATH "$out/share/openhands/frontend" \
      --prefix PATH : "${pkgs.lib.makeBinPath runtimeDeps}"
    
    # Create a server wrapper script for web UI mode
    makeWrapper ${pythonPackage}/bin/python $out/bin/openhands-server \
      --add-flags "-m openhands.server.main" \
      --set PYTHONPATH "$out/lib:$PYTHONPATH" \
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