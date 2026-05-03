{
  config,
  lib,
  pkgs,
  hostVars,
  ...
}:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-treesitter-textobjects
      (nvim-treesitter.withPlugins (p: [
        p.tree-sitter-nix
        p.tree-sitter-vim
        p.tree-sitter-vimdoc
        p.tree-sitter-bash
        p.tree-sitter-regex
        p.tree-sitter-lua
        p.tree-sitter-markdown
        p.tree-sitter-markdown-inline
        p.tree-sitter-c
        p.tree-sitter-python
        p.tree-sitter-json
        p.tree-sitter-yaml
        p.tree-sitter-html
        p.tree-sitter-css
        p.tree-sitter-javascript
        p.tree-sitter-typescript
        p.tree-sitter-tsx
        p.tree-sitter-toml

        p.tree-sitter-gitcommit
        p.tree-sitter-gitignore

        p.tree-sitter-terraform
        p.tree-sitter-hcl
      ]))
    ];

    extraPackages = with pkgs; [
      lua-language-server
      stylua
      nil
      nodePackages.prettier
      nodePackages.vscode-langservers-extracted
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
    ];
  };

  # xdg.configFile."nvim".source =
  #   config.lib.file.mkOutOfStoreSymlink "${hostVars.nixConfig}/dotfiles/nvim";

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "/home/nagih/Workspaces/config/dotfiles/nvim";

  programs.zsh.shellAliases = {
    v = "nvim";
    vi = "nvim";
    vim = "nvim";
  };

  home.packages = with pkgs; [
    ranger
    tree-sitter
    lua51Packages.lua
    luarocks
    glow
    github-cli

    terraform-ls
    trivy
  ];
}
