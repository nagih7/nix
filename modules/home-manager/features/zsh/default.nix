{ config, pkgs, ... }:

{
  # === ZSH MODERN SHELL CONFIGURATION ===
  programs.zsh = {
    enable = true;
    enableCompletion = true; # Enable advanced tab completion
    autosuggestion.enable = true; # Enable command autosuggestions based on history
    syntaxHighlighting.enable = true; # Enable command syntax highlighting

    # === MODERN ZSH CONFIGURATION ===
    history = {
      size = 50000; # Increase history size significantly
      save = 50000; # Save more history to file
      share = true; # Share history between all zsh sessions
      ignoreDups = true; # Ignore duplicate entries
      ignoreSpace = true; # Ignore commands starting with space
      expireDuplicatesFirst = true; # Remove duplicates first when trimming history
    };

    # === OH-MY-ZSH INTEGRATION ===
    oh-my-zsh = {
      enable = true;

      plugins = [
        # === ESSENTIAL PRODUCTIVITY PLUGINS ===
        "git" # Git aliases and completions
        "docker" # Docker command completion
        "docker-compose" # Docker Compose completion
        "kubectl" # Kubernetes completion
        "systemd" # Systemd command completion
        "ssh-agent" # SSH key management
        "gpg-agent" # GPG key management

        # === NAVIGATION AND SEARCH ===
        "fzf" # Fuzzy finder integration
        "z" # Smart directory jumping
        "web-search" # Quick web searches from terminal

        # === DEVELOPMENT TOOLS ===
        "node" # Node.js utilities
        "npm" # NPM completion
        "python" # Python utilities
        "rust" # Rust/Cargo completion
        "golang" # Go development tools

        # === MODERN CLI INTEGRATION ===
        "colored-man-pages" # Colorized man pages
        "command-not-found" # Suggest packages for missing commands
        "history-substring-search" # Better history search

        # === UTILITY PLUGINS ===
        "extract" # Smart extraction for any archive
        "copyfile" # Copy file contents to clipboard
        "copypath" # Copy current path to clipboard
        "sudo" # Double ESC to add sudo to command
      ];
    };

    # === ADVANCED SHELL ALIASES ===
    shellAliases = {
      # === FILE OPERATIONS (Enhanced) ===
      ll = "eza -la --icons --git --header"; # Enhanced long listing
      la = "eza -a --icons"; # List all with icons
      lt = "eza -la --icons --git --tree --level=2"; # Tree view
      lg = "eza -la --icons --git --git-ignore"; # Git-aware listing

      # === MODERN CLI REPLACEMENTS ===
      ls = "eza --icons --group-directories-first"; # Better ls with icons
      grep = "rg --color=auto --smart-case"; # Better grep with smart case
      find = "fd --color=auto"; # Better find
      du = "dust"; # Modern disk usage
      df = "duf"; # Modern disk free
      ps = "procs"; # Modern process viewer
      top = "htop"; # Modern system monitor

      # === GIT WORKFLOW (Enhanced) ===
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

      # === TMUX WORKFLOW (Enhanced) ===
      tm = "tmux";
      tma = "tmux attach-session -t";
      tmn = "tmux new-session -s";
      tml = "tmux list-sessions";
      tmk = "tmux kill-session -t";
      tmd = "tmux detach";
      tmcls = "rm -rf ~/.tmux/resurrect/*";

      # === NPM WORKFLOW (Enhanced) ===
      npm-list-global = "npm list -g --depth=0";
      npm-outdated-global = "npm outdated -g";
      npm-update-global = "npm update -g";

      # === QUICK UTILITIES ===
      h = "history"; # Fuzzy history search
      hg = "history | grep"; # Grep history
      weather = "curl wttr.in"; # Quick weather
      ip = "curl ifconfig.me"; # Public IP
      localip = "ip route get 1 | awk '{print \$7}'"; # Local IP
      ports = "netstat -tulanp"; # Show open ports

      # === DIRECTORY OPERATIONS ===
      md = "mkdir -pv"; # Create directory with parents
      rd = "rmdir"; # Remove directory

      # === FILE VIEWING AND EDITING ===
      v = "nvim"; # Quick vim
      e = "\$EDITOR"; # Default editor

      # === CLIPBOARD OPERATIONS ===
      copy = "wl-copy"; # Copy to clipboard
      paste = "wl-paste"; # Paste from clipboard

      # === SYSTEM INFO ===
      sysinfo = "neofetch"; # System information
      diskinfo = "df -h"; # Disk usage
      meminfo = "free -h"; # Memory usage
    };

    # === ADVANCED ZSH CONFIGURATION ===
    initContent = ''
      # === MODERN ZSH OPTIONS ===
      setopt AUTO_CD              # cd to directory by typing name
      setopt AUTO_PUSHD           # automatically push directories to stack
      setopt PUSHD_IGNORE_DUPS    # ignore duplicate directories in stack
      setopt PUSHD_SILENT         # don't print directory stack
      setopt CORRECT              # command auto-correction
      setopt CORRECT_ALL          # argument auto-correction
      setopt GLOB_DOTS            # include dotfiles in globbing
      setopt EXTENDED_GLOB        # extended globbing features
      setopt NUMERIC_GLOB_SORT    # sort globs numerically

      # === HISTORY OPTIMIZATION ===
      setopt HIST_FIND_NO_DUPS    # don't show duplicates in history search
      setopt HIST_REDUCE_BLANKS   # remove unnecessary blanks from history
      setopt HIST_VERIFY          # show command before executing from history
      setopt INC_APPEND_HISTORY   # immediately append to history

      # === COMPLETION ENHANCEMENTS ===
      setopt COMPLETE_IN_WORD     # complete from both ends of word
      setopt AUTO_MENU            # show completion menu on tab
      setopt AUTO_LIST            # automatically list choices on ambiguous completion
      setopt AUTO_PARAM_SLASH     # add slash after directory names
      setopt FLOW_CONTROL         # disable flow control (Ctrl+S/Ctrl+Q)
      unsetopt FLOW_CONTROL

      # === KEY BINDINGS (Emacs-style) ===
      bindkey '^A' beginning-of-line      # Ctrl+A: beginning of line
      bindkey '^E' end-of-line            # Ctrl+E: end of line
      bindkey '^R' history-incremental-search-backward  # Ctrl+R: reverse search
      bindkey '^[[A' history-substring-search-up        # Up arrow: search up
      bindkey '^[[B' history-substring-search-down      # Down arrow: search down

      # === FZF INTEGRATION ===
      if command -v fzf &> /dev/null; then
        # FZF default options
        export FZF_DEFAULT_OPTS="
          --height 40% 
          --layout=reverse 
          --border 
          --preview 'bat --color=always --style=numbers --line-range=:500 {}'
          --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
          --color=fg:#cdd6f4,header:#f38ba8,info:#cba6ac,pointer:#f5e0dc
          --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6ac,hl+:#f38ba8"
        
        # Use fd for file searching if available
        if command -v fd &> /dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
          export FZF_ALT_C_COMMAND='fd --type d . --strip-cwd-prefix --hidden --follow --exclude .git'
        fi
      fi

      # === MODERN DIRECTORY NAVIGATION ===
      # Auto ls after cd
      chpwd() {
        emulate -L zsh
        eza --icons --group-directories-first
      }

      # === DEVELOPMENT ENVIRONMENT VARIABLES ===
      export EDITOR="nvim"
      export VISUAL="nvim"
      export BROWSER="brave"
      export TERMINAL="wezterm"
      export MANPAGER="nvim +Man!"

      # === PERFORMANCE OPTIMIZATIONS ===
      export HISTFILE="$HOME/.zsh_history"
      export HISTSIZE=50000
      export SAVEHIST=50000

      # === PATH ENHANCEMENTS ===
      typeset -U PATH path  # Remove duplicates from PATH

      # === MODERN CLI TOOL PREFERENCES ===
      export EZA_COLORS="da=36:di=34:fi=0:ln=35:pi=33:so=32:bd=33:cd=33:or=31:mi=31:ex=32"

      export PATH="$HOME/.local/bin:$PATH"
      
      zstyle ':completion:*' menu no
    '';
  };

  # === ADDITIONAL PACKAGES FOR ZSH ===
  home.packages = with pkgs; [
    # === MODERN CLI TOOLS ===
    zsh-autosuggestions # Command autosuggestions
    zsh-syntax-highlighting # Syntax highlighting
    zsh-history-substring-search # Better history search

    # === ENHANCED CLI TOOLS ===
    dust # Modern du replacement
    duf # Modern df replacement
    procs # Modern ps replacement
  ];
}
