#!/usr/bin/env zsh

#======================================================================#
#                                                                      #
#   __________              ___________.__                             #
#   \____    /____   ____   \__    ___/|  |__   ____   _____   ____    #
#     /     // __ \ /    \    |    |   |  |  \_/ __ \ /     \_/ __ \   #
#    /     /\  ___/|   |  \   |    |   |   Y  \  ___/|  Y Y  \  ___/   #
#   /_______ \___  >___|  /   |____|   |___|  /\___  >__|_|  /\___  >  #
#           \/   \/     \/                  \/     \/      \/     \/   #
#                        Zen Minimal Theme                             #
#                 by Michael Garcia a.k.a. thecrazygm                  #
#                                                                      #
#                    https://peakd.com/@thecrazygm                     #
#======================================================================#

#======================================================================#
#                          Configuration Options                       #
#======================================================================#

export VIRTUAL_ENV_DISABLE_PROMPT=true
# export ZEN_THEME_SHOW_TIME=true
# export ZEN_THEME_TWO_LINES=true
# export ZEN_THEME_SHOW_EXEC_TIME=true
# export ZEN_THEME_EXEC_TIME_THRESHOLD=2
# export ZEN_THEME_PATH_TRUNCATE=2

#======================================================================#
#                          Color Definitions                           #
#======================================================================#

ZEN_COLOR_BLUE="%F{4}"          # Blue - SSH username
ZEN_COLOR_PURPLE="%F{5}"        # Purple - SSH hostname
ZEN_COLOR_CYAN="%F{6}"          # Cyan - Local username, stash count
ZEN_COLOR_GRAY="%F{8}"          # Gray - Separator, path, time
ZEN_COLOR_GREEN="%F{10}"        # Green - Clean repo, staged changes
ZEN_COLOR_YELLOW="%F{11}"       # Yellow - Dirty repo, unstaged changes
ZEN_COLOR_LIGHT_BLUE="%F{12}"   # Light blue - Local hostname
ZEN_COLOR_LIGHT_CYAN="%F{14}"   # Light cyan - Ahead indicator
ZEN_COLOR_MAGENTA="%F{13}"      # Magenta - Behind indicator
ZEN_COLOR_RED="%F{196}"         # Red - Root prompt, error code
ZEN_COLOR_ORANGE="%F{214}"      # Orange - Normal prompt
ZEN_COLOR_DEEP_ORANGE="%F{202}" # Deep orange - Virtual env
ZEN_COLOR_RESET="%f"            # Reset color

#======================================================================#
#                          Core Functions                              #
#======================================================================#

# Prompt
zen_get_prompt() {
  local ssh_status=$(zen_get_ssh_status)
  local prompt_start=""
  local prompt_end=""

  # Two-line prompt format if enabled
  if [[ -v ZEN_THEME_TWO_LINES ]]; then
    prompt_end="\n"
  fi

  echo -n "${prompt_start}"

  # Username color changes based on SSH status
  if [[ "$ssh_status" == "ssh" ]]; then
    echo -n "${ZEN_COLOR_BLUE}%n"  # Blue for SSH
  else
    echo -n "${ZEN_COLOR_CYAN}%n"  # Cyan for local
  fi

  echo -n "${ZEN_COLOR_GRAY}@"

  # Hostname color changes based on SSH status
  if [[ "$ssh_status" == "ssh" ]]; then
    echo -n "${ZEN_COLOR_PURPLE}%m"  # Purple for SSH
  else
    echo -n "${ZEN_COLOR_LIGHT_BLUE}%m"  # Light blue for local
  fi

  echo -n "${ZEN_COLOR_GRAY}:"
  echo -n "$(zen_get_path_display)"
  echo -n " "

  # Git branch information with enhanced status
  echo -n "$(zen_git_status)"

  echo -n "${prompt_end}"

  # Prompt symbol changes color based on user privileges and last command status
  if [[ $UID -eq 0 ]]; then
    echo -n "${ZEN_COLOR_RED}#${ZEN_COLOR_RESET} "  # Red for root
  else
    echo -n "%(?.${ZEN_COLOR_ORANGE}.${ZEN_COLOR_RED})\$${ZEN_COLOR_RESET} "  # Orange for normal user, red if last command failed
  fi
}

# Right Prompt
zen_get_rprompt() {
  # Command execution time
  local exec_time=$(zen_cmd_exec_time)
  if [[ -n "$exec_time" ]]; then
    echo -n "${ZEN_COLOR_GRAY}${exec_time}${ZEN_COLOR_RESET} "
  fi

  # Return code if non-zero with arrow symbol
  echo -n "%(?..${ZEN_COLOR_RED}‹%?›${ZEN_COLOR_RESET} ↵)"

  # Virtual environment indicator
  if [[ -v VIRTUAL_ENV ]]; then
    echo -n "${ZEN_COLOR_DEEP_ORANGE} ["$(basename "$VIRTUAL_ENV")"]${ZEN_COLOR_RESET}"
  fi

  # Time display if enabled
  if [[ -v ZEN_THEME_SHOW_TIME ]]; then
    echo -n "${ZEN_COLOR_GRAY} [%D{%H:%M:%S}]${ZEN_COLOR_RESET}"
  fi

  # SSH indicator
  if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    echo -n "${ZEN_COLOR_BLUE} [SSH]${ZEN_COLOR_RESET}"
  fi
}

#======================================================================#
#                          Git Functions                               #
#======================================================================#

# Git status with better indicators
zen_git_status() {
  # Get branch name, return early if not in a git repo
  local git_branch=$(zen_safe_git_command "" rev-parse --abbrev-ref HEAD)
  if [[ -z "$git_branch" ]]; then
    return 0
  fi

  if [[ -n "$git_branch" ]]; then
    # Get various git statuses with proper error handling using our helper function
    local git_status=$(zen_safe_git_command "" status --porcelain)
    local git_ahead=$(zen_safe_git_command "0" rev-list --count @{upstream}..HEAD)
    local git_behind=$(zen_safe_git_command "0" rev-list --count HEAD..@{upstream})

    # Special handling for stash count which requires piping
    local git_stash_count="0"
    if command -v git >/dev/null 2>&1; then
      git_stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ') || git_stash_count="0"
    fi

    # Default color for clean repo
    local git_color="${ZEN_COLOR_GREEN}"
    local git_status_symbol=""
    local git_indicators=""

    # Check if repo has changes
    if [[ -n "$git_status" ]]; then
      # Count different types of changes
      local staged=$(echo "$git_status" | grep -E '^[MADRC]' | wc -l | tr -d ' ')
      local unstaged=$(echo "$git_status" | grep -E '^.[MADRC]' | wc -l | tr -d ' ')
      local untracked=$(echo "$git_status" | grep -E '\?\?' | wc -l | tr -d ' ')

      git_color="${ZEN_COLOR_YELLOW}"

      # More detailed status indicators with consistent spacing
      if [[ $staged -gt 0 ]]; then
        git_indicators="${git_indicators} ${ZEN_COLOR_GREEN}●${staged}${ZEN_COLOR_RESET} "
      fi
      if [[ $unstaged -gt 0 ]]; then
        git_indicators="${git_indicators} ${ZEN_COLOR_YELLOW}●${unstaged}${ZEN_COLOR_RESET} "
      fi
      if [[ $untracked -gt 0 ]]; then
        git_indicators="${git_indicators} ${ZEN_COLOR_GRAY}●${untracked}${ZEN_COLOR_RESET} "
      fi
    else
      git_status_symbol=" ${ZEN_COLOR_GREEN}✓${ZEN_COLOR_RESET}"
    fi

    # Add ahead/behind indicators
    if [[ -n "$git_ahead" && "$git_ahead" != "0" ]]; then
      git_indicators="${git_indicators} ${ZEN_COLOR_LIGHT_CYAN}↑${git_ahead}${ZEN_COLOR_RESET} "
    fi
    if [[ -n "$git_behind" && "$git_behind" != "0" ]]; then
      git_indicators="${git_indicators} ${ZEN_COLOR_MAGENTA}↓${git_behind}${ZEN_COLOR_RESET} "
    fi

    # Add stash indicator
    if [[ "$git_stash_count" != "0" ]]; then
      git_indicators="${git_indicators} ${ZEN_COLOR_CYAN}≡${git_stash_count}${ZEN_COLOR_RESET} "
    fi

    # Output the branch name and all indicators with consistent spacing
    echo -n "${git_color}‹${git_branch}›%f${git_status_symbol}${git_indicators}"
  fi
}

# Helper function for safe git command execution
zen_safe_git_command() {
  local default_value="$1"
  shift

  if ! command -v git >/dev/null 2>&1; then
    echo "$default_value"
    return 0
  fi

  local result
  result=$(git --no-optional-locks "$@" 2>/dev/null) || result="$default_value"
  echo "$result"
}

#======================================================================#
#                          Helper Functions                            #
#======================================================================#

# Function to determine SSH connection and set colors
zen_get_ssh_status() {
  if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    echo "ssh"
  else
    echo "local"
  fi
}

# Function to display directory with optional truncation
zen_get_path_display() {
  local current_path="%~"

  # Apply truncation if enabled
  if [[ -v ZEN_THEME_PATH_TRUNCATE ]]; then
    if [[ $ZEN_THEME_PATH_TRUNCATE -eq 1 ]]; then
      # Show only the current directory
      current_path="%1~"
    elif [[ $ZEN_THEME_PATH_TRUNCATE -gt 1 ]]; then
      # Show limited number of path segments
      current_path="%$ZEN_THEME_PATH_TRUNCATE~"
    fi
  fi

  # Display path with color
  echo -n "${ZEN_COLOR_GRAY}${current_path}${ZEN_COLOR_RESET}"
}

# Command execution time display with improved formatting
zen_cmd_exec_time() {
  # Only process if execution time display is enabled and we have a valid execution time
  if [[ -v ZEN_THEME_SHOW_EXEC_TIME && -v ZEN_CMD_EXEC_TIME ]]; then
    # Ensure we have a numeric value
    if [[ -n "$ZEN_CMD_EXEC_TIME" && "$ZEN_CMD_EXEC_TIME" =~ ^[0-9]+$ ]]; then
      # Calculate hours, minutes, seconds
      local hours=$(($ZEN_CMD_EXEC_TIME / 3600))
      local minutes=$((($ZEN_CMD_EXEC_TIME - $hours * 3600) / 60))
      local seconds=$(($ZEN_CMD_EXEC_TIME - $hours * 3600 - $minutes * 60))
      local time_str=""

      # Format the time string based on duration
      if [[ $hours -gt 0 ]]; then
        # Include hours, minutes, seconds
        time_str="${hours}h${minutes}m${seconds}s"
      elif [[ $minutes -gt 0 ]]; then
        # Include minutes, seconds
        time_str="${minutes}m${seconds}s"
      else
        # Only seconds
        time_str="${seconds}s"
      fi

      # Output the formatted time string
      echo "${ZEN_COLOR_GRAY}took ${time_str}${ZEN_COLOR_RESET}"
    fi
  fi
}

#======================================================================#
#                          Prompt Setup                                #
#======================================================================#

setopt PROMPT_SUBST
export PROMPT='$(zen_get_prompt)'
export RPROMPT='$(zen_get_rprompt)'

#======================================================================#
#                          Hooks for Command Execution Time            #
#======================================================================#

preexec() {
  ZEN_CMD_START_TIME=$SECONDS
}

precmd() {
  if [[ -v ZEN_CMD_START_TIME && -n "$ZEN_CMD_START_TIME" ]]; then
    ZEN_CMD_EXEC_TIME=$(($SECONDS - $ZEN_CMD_START_TIME))
    unset ZEN_CMD_START_TIME

    # Get threshold value or use default of 5 seconds
    local threshold=5
    if [[ -v ZEN_THEME_EXEC_TIME_THRESHOLD && -n "$ZEN_THEME_EXEC_TIME_THRESHOLD" ]]; then
      threshold=$ZEN_THEME_EXEC_TIME_THRESHOLD
    fi

    # Only show execution time for commands that take longer than the threshold
    if [[ $ZEN_CMD_EXEC_TIME -lt $threshold ]]; then
      unset ZEN_CMD_EXEC_TIME
    fi
  fi
}

#======================================================================#
#                          Virtualenv Support                          #
#======================================================================#

# --- Helper functions (if they don't already exist) ---
# These provide defaults if the corresponding tools aren't installed

if ! (( $+functions[git_prompt_info] )); then
  function git_prompt_info() { echo "" }
fi

if ! (( $+functions[virtualenv_prompt_info] )); then
  function virtualenv_prompt_info() { echo "" }
fi

# ZSH Theme configuration for compatibility with plugins
ZSH_THEME_GIT_PROMPT_PREFIX="${ZEN_COLOR_ORANGE}% ‹"
ZSH_THEME_GIT_PROMPT_SUFFIX="›${ZEN_COLOR_RESET}"
ZSH_THEME_GIT_PROMPT_DIRTY="${ZEN_COLOR_YELLOW}✗ "
ZSH_THEME_GIT_PROMPT_CLEAN="${ZEN_COLOR_GREEN}✓ "

ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX="${ZEN_COLOR_DEEP_ORANGE}% ["
ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX="]${ZEN_COLOR_RESET}"
ZSH_THEME_VIRTUALENV_PREFIX=$ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX
ZSH_THEME_VIRTUALENV_SUFFIX=$ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX
