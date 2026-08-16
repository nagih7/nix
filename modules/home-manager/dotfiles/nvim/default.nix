{
  config,
  pkgs,
  hostVars,
  nagih7-dots,
  ...
}:

{
  # Cấu hình Neovim: Dùng flake input nagih7-dots (github:nagih7/dotfiles) thay vì local symlink.
  # Cài đặt Neovim qua home.packages thay vì programs.neovim để tránh xung đột file init.lua
  home.packages = with pkgs; [
    neovim
    
    # LSPs, Formatters & Tools
    lua-language-server
    stylua
    nil
    prettier
    vscode-langservers-extracted
    nixpkgs-fmt
    typescript-language-server
    python3Packages.python-lsp-server
    black
    isort
    rust-analyzer
    rustfmt
    tree-sitter
    lazygit
    sqlite
    trash-cli
    imagemagick
    ghostscript
    mermaid-cli
    tectonic
    gcc
    gnumake

    # Other Utilities
    ranger
    lua51Packages.lua
    luarocks
    glow
    github-cli
    terraform-ls
    trivy
  ];

  # Dùng flake input: lazy-lock.json được đặt trong stdpath("data") để writable.
  # Để update plugin: push dotfiles → nix flake update nagih7-dots → nixos-rebuild switch.
  xdg.configFile."nvim".source = "${nagih7-dots}/nvim";

  programs.zsh.shellAliases = {
    v = "nvim";
    vi = "nvim";
    vim = "nvim";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
