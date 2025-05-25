{ pkgs, system }:

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
    pre-commit
  ]);
in
pkgs.mkShell {
  buildInputs = [
    pythonEnv
    pkgs.nodejs_20
    pkgs.nodePackages.npm
    pkgs.tmux
    pkgs.chromium
  ];
  
  shellHook = ''
    export PYTHONPATH=$PWD:$PYTHONPATH
    export OPENHANDS_FRONTEND_PATH=$PWD/frontend/build
    
    echo "OpenHands development environment"
    echo "Run 'make build' to build the project"
    echo "Run 'make run' to start the application"
  '';
}