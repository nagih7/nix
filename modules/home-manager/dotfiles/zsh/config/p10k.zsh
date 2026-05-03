
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# === LEAN PROMPT STYLE ===
# The list of segments shown on the left. Fill it with the most important segments.
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  prompt_char           # prompt symbol
  virtualenv            # python virtual environment
  dir                   # current directory
  vcs                   # git info
)

# The list of segments shown on the right. Fill it with less important segments.
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status                      # exit code of the last command
  command_execution_time      # duration of the last command
  background_jobs             # presence of background jobs
)

# === LEAN STYLE CONFIGURATION ===
# Define prompt style: lean (single line)
typeset -g POWERLEVEL9K_MODE='unicode'
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false

# === SEGMENT SEPARATORS & SPACING ===
# Segment separators for lean style
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=' '

# Remove any leading/trailing whitespace
typeset -g POWERLEVEL9K_WHITESPACE_BETWEEN_LEFT_SEGMENTS=''
typeset -g POWERLEVEL9K_WHITESPACE_BETWEEN_RIGHT_SEGMENTS=''

# === PROMPT CHARACTER ===
# Colors
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76    # Tokyo Night green
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196 # Tokyo Night red
typeset -g POWERLEVEL9K_PROMPT_CHAR_BACKGROUND=

# Symbols for different modes
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='➜'
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='◄'
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='◆'
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='➤'

# === DIRECTORY ===
typeset -g POWERLEVEL9K_DIR_FOREGROUND=39            # Tokyo Night blue
typeset -g POWERLEVEL9K_DIR_BACKGROUND=
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_last
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=250  # Light gray
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=30
# Hide DIR segment when in home directory
typeset -g POWERLEVEL9K_DIR_HOME_VISUAL_IDENTIFIER_EXPANSION=''
typeset -g POWERLEVEL9K_DIR_HOME_CONTENT_EXPANSION=''

# === VCS (GIT) ===
# Git status colors (no background)
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76       # Tokyo Night green
typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=220  # Tokyo Night yellow
typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=196   # Tokyo Night red
typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=

# Simplified git icon
typeset -g POWERLEVEL9K_VCS_GIT_ICON='±'
typeset -g POWERLEVEL9K_VCS_GIT_GITHUB_ICON='±'
typeset -g POWERLEVEL9K_VCS_GIT_GITLAB_ICON='±'
typeset -g POWERLEVEL9K_VCS_GIT_BITBUCKET_ICON='±'

# === COMMAND EXECUTION TIME ===
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=220  # Tokyo Night yellow
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=

# === STATUS ===
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196    # Tokyo Night red
typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND=

# === BACKGROUND JOBS ===
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=220 # Tokyo Night yellow
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=

# === VIRTUAL ENVIRONMENT ===
typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=76       # Tokyo Night green
typeset -g POWERLEVEL9K_VIRTUALENV_BACKGROUND=
typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
typeset -g POWERLEVEL9K_VIRTUALENV_LEFT_DELIMITER='('
typeset -g POWERLEVEL9K_VIRTUALENV_RIGHT_DELIMITER=')'
typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYTHON=false
typeset -g POWERLEVEL9K_VIRTUALENV_USE_PYTHON_VERSION=false
typeset -g POWERLEVEL9K_VIRTUALENV_CONTENT_EXPANSION='(${VIRTUAL_ENV:t})'

# === PERFORMANCE & FEATURES ===
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

# === VISUAL SETTINGS ===
typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
typeset -g POWERLEVEL9K_COLOR_SCHEME='256' 