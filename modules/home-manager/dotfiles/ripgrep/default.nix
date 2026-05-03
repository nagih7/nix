{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    ripgrep
  ];

  xdg.configFile."ripgrep/ripgreprc".text = ''
    --colors=line:fg:yellow
    --colors=line:style:bold
    --colors=path:fg:green
    --colors=path:style:bold
    --colors=match:fg:black
    --colors=match:bg:yellow
    --colors=match:style:nobold
    # Default behavior
    --smart-case
    --hidden
    --follow
    --glob=!.git/*
    --glob=!node_modules/*
    --glob=!.next/*
    --glob=!dist/*
    --glob=!build/*
    --glob=!target/*
    --glob=!*.min.js
    --glob=!*.min.css
    # Output formatting
    --max-columns=150
    --max-columns-preview
    # Performance
    --mmap
  '';

  home.sessionVariables = {
    RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/ripgreprc";
  };

  home.shellAliases = {
    rg = "rg";
    rgf = "rg --files";
    rgi = "rg --ignore-case";
    rgv = "rg --invert-match";
    rgl = "rg --files-with-matches";
    rgc = "rg --count";
  };
}
