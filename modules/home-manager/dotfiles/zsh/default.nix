{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # These three pull in the matching zsh-* packages; no need to list them
    # in home.packages as well.
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    history = {
      size = 50000;
      save = 50000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };

    oh-my-zsh = {
      enable = true;
      # fzf / z / command-not-found are provided by the home-manager modules
      # below (programs.fzf, programs.zoxide, programs.nix-index).
      plugins = [
        "git"
        "docker"
        "docker-compose"
        "kubectl"
        "systemd"
        "ssh-agent"
        "gpg-agent"
        "web-search"
        "node"
        "npm"
        "python"
        "rust"
        "golang"
        "colored-man-pages"
        "extract"
        "copyfile"
        "copypath"
        "sudo"
      ];
    };

    shellAliases = {
      # === FILE LISTING ===
      ll = "eza -la --icons --git --header";
      la = "eza -a --icons";
      lt = "eza -la --icons --git --tree --level=2";
      lg = "eza -la --icons --git --git-ignore";

      # === MODERN CLI REPLACEMENTS ===
      ls = "eza --icons --group-directories-first";
      grep = "rg --color=auto --smart-case";
      find = "fd --color=auto";
      du = "dust";
      df = "duf";
      ps = "procs";
      top = "htop";
      cat = "bat --paging=never";

      # === GIT ===
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gc = "git commit -v";
      gcm = "git commit -m";
      gco = "git checkout";
      gcb = "git checkout -b";
      gd = "git diff";
      gds = "git diff --staged";
      gf = "git fetch";
      gl = "git log --oneline --graph --decorate";
      gp = "git push";
      gpl = "git pull";
      gs = "git status --short";
      gst = "git status";
      gcaa = "git add . && git commit --amend --no-edit";

      # === TMUX ===
      tm = "tmux";
      tma = "tmux attach-session -t";
      tmn = "tmux new-session -s";
      tml = "tmux list-sessions";
      tmk = "tmux kill-session -t";
      tmd = "tmux detach";
      tmcls = "rm -rf ~/.tmux/resurrect/*";

      # === NPM ===
      npm-list-global = "npm list -g --depth=0";
      npm-outdated-global = "npm outdated -g";
      npm-update-global = "npm update -g";

      # === QUICK UTILITIES ===
      h = "history";
      hg = "history | grep";
      weather = "curl wttr.in";
      ip = "curl ifconfig.me";
      localip = "ip route get 1 | awk '{print \$7}'";
      ports = "netstat -tulanp";
      md = "mkdir -pv";
      rd = "rmdir";
      v = "nvim";
      e = "\$EDITOR";
      copy = "wl-copy";
      paste = "wl-paste";
      sysinfo = "fastfetch";
      diskinfo = "df -h";
      meminfo = "free -h";
    };

    initContent = ''
      # === OPTIONS ===
      setopt AUTO_CD              # cd to directory by typing name
      setopt AUTO_PUSHD           # automatically push directories to stack
      setopt PUSHD_IGNORE_DUPS    # ignore duplicate directories in stack
      setopt PUSHD_SILENT         # don't print directory stack
      setopt CORRECT              # command auto-correction
      setopt CORRECT_ALL          # argument auto-correction
      setopt GLOB_DOTS            # include dotfiles in globbing
      setopt EXTENDED_GLOB        # extended globbing features
      setopt NUMERIC_GLOB_SORT    # sort globs numerically

      # === HISTORY ===
      setopt HIST_FIND_NO_DUPS    # don't show duplicates in history search
      setopt HIST_REDUCE_BLANKS   # remove unnecessary blanks from history
      setopt HIST_VERIFY          # show command before executing from history
      setopt INC_APPEND_HISTORY   # immediately append to history

      # === COMPLETION ===
      setopt COMPLETE_IN_WORD     # complete from both ends of word
      setopt AUTO_MENU            # show completion menu on tab
      setopt AUTO_LIST            # automatically list choices on ambiguous completion
      setopt AUTO_PARAM_SLASH     # add slash after directory names
      unsetopt FLOW_CONTROL       # free Ctrl+S/Ctrl+Q
      zstyle ':completion:*' menu no

      # === KEY BINDINGS (Emacs-style) ===
      bindkey '^A' beginning-of-line
      bindkey '^E' end-of-line
      bindkey '^R' history-incremental-search-backward
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # Auto ls after cd
      chpwd() {
        emulate -L zsh
        eza --icons --group-directories-first
      }

      typeset -U PATH path  # Remove duplicates from PATH
      export PATH="$HOME/.local/bin:$PATH"
      export EZA_COLORS="da=36:di=34:fi=0:ln=35:pi=33:so=32:bd=33:cd=33:or=31:mi=31:ex=32"
    '';
  };

  # fzf keybindings/completion (Ctrl+T, Alt+C) + fd as the file source.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d . --strip-cwd-prefix --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    ];
    colors = {
      "bg+" = "#313244";
      bg = "#1e1e2e";
      spinner = "#f5e0dc";
      hl = "#f38ba8";
      fg = "#cdd6f4";
      header = "#f38ba8";
      info = "#cba6ac";
      pointer = "#f5e0dc";
      marker = "#f5e0dc";
      "fg+" = "#cdd6f4";
      prompt = "#cba6ac";
      "hl+" = "#f38ba8";
    };
  };

  # `z` / `zi` directory jumping (replaces the oh-my-zsh `z` plugin).
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat.enable = true;

  # command-not-found handler backed by nix-index (the channel-based
  # programs.command-not-found has no database on a flake system).
  # Run `nix-index` once (or subscribe to nix-index-database) to build it.
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    dust # du
    duf # df
    procs # ps
  ];
}
