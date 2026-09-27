{
  pkgs,
  nagih7-dots,
  ...
}:

{
  # Neovim config comes from the nagih7-dots flake input (github:nagih7/dotfiles).
  # Installed via home.packages rather than programs.neovim so home-manager
  # doesn't fight over init.lua. To update plugins: push dotfiles →
  # `nix flake update nagih7-dots` → rebuild.
  #
  # Python formatters (black/isort) come from development/lsp/python.nix,
  # gnumake from development/cli.nix, imagemagick from the quickshell deps.
  home.packages = with pkgs; [
    neovim

    # LSPs, Formatters & Tools
    lua-language-server
    stylua
    nil # nil_ls in nvim/lua/preferences.lua
    prettier
    vscode-langservers-extracted
    typescript-language-server
    python3Packages.python-lsp-server
    rust-analyzer
    rustfmt
    tree-sitter
    lazygit
    sqlite
    trash-cli
    ghostscript
    mermaid-cli
    tectonic
    gcc # treesitter parser builds

    # Other Utilities
    ranger
    lua51Packages.lua
    luarocks
    github-cli
    terraform-ls
    trivy
  ];

  # lazy-lock.json lives in stdpath("data") so it stays writable.
  xdg.configFile."nvim".source = "${nagih7-dots}/nvim";

  # EDITOR/VISUAL and the `v` alias are set in home/common and dotfiles/zsh.
  programs.zsh.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };
}
