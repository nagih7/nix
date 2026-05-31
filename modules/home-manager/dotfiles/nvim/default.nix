{
  config,
  pkgs,
  hostVars,
  ...
}:

{
  # Cấu hình Neovim: Sử dụng symlink trực tiếp từ dotfiles để linh hoạt (NvChad/LazyVim)
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

  # Symlink toàn bộ thư mục nvim từ dotfiles ra ngoài store (Mutable config)
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${hostVars.nixConfig}/dotfiles/nvim";

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
