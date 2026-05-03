{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      init.defaultBranch = "main";
      push.default = "simple";
      pull.rebase = false;
      core.editor = "nvim";
      core.pager = "delta";

      interactive.diffFilter = "delta --color-only";

      delta = {
        features = "side-by-side line-numbers decorations";
        syntax-theme = "TwoDark";
        plus-style = "syntax #012800";
        minus-style = "syntax #340001";
        line-numbers = true;
        decorations = true;
      };

      "delta \"decorations\"" = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
        hunk-header-decoration-style = "cyan box ul";
      };

      "delta \"line-numbers\"" = {
        line-numbers-left-style = "cyan";
        line-numbers-right-style = "cyan";
        line-numbers-minus-style = "124";
        line-numbers-plus-style = "28";
      };

      diff = {
        colorMoved = "default";
        tool = "delta";
      };

      merge.conflictstyle = "diff3";
    };
  };
}
