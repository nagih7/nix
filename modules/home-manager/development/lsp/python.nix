{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # === PYTHON CORE ===
    python3
    python3Packages.pip
    python3Packages.setuptools

    # === PYTHON DEVELOPMENT TOOLS ===
    python3Packages.debugpy # Required for nvim-dap-python
    python3Packages.pytest # Main testing framework
    python3Packages.black # Code formatter
    python3Packages.isort # Import sorter
    python3Packages.flake8 # Linter
    python3Packages.ipython # Enhanced REPL
    python3Packages.virtualenv # Virtual environment manager
  ];

  # === PYTHON ENVIRONMENT VARIABLES ===
  home.sessionVariables = {
    PYTHONDONTWRITEBYTECODE = "1"; # Don't create .pyc files
  };
}
