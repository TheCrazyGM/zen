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
#                    https://hive.blog/thecrazygm                      #
#                                                                      #
#======================================================================#

export VIRTUAL_ENV_DISABLE_PROMPT=true
# Uncomment to show time in prompt
# export ZEN_THEME_SHOW_TIME=true
# Uncomment for two-line prompt
# export ZEN_THEME_TWO_LINES=true
# Uncomment to show command execution time for commands that take longer than 5 seconds
# export ZEN_THEME_SHOW_EXEC_TIME=true
setopt PROMPT_SUBST

# Function to determine SSH connection and set colors
zen_get_ssh_status() {
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    echo "ssh"
  else
    echo "local"
  fi
}

# Git status with better indicators
zen_git_status() {
  local git_branch=$(git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n "$git_branch" ]]; then
    # Get various git statuses
    local git_status=$(git --no-optional-locks status --porcelain 2>/dev/null)
    local git_ahead=$(git --no-optional-locks rev-list --count @{upstream}..HEAD 2>/dev/null)
    local git_behind=$(git --no-optional-locks rev-list --count HEAD..@{upstream} 2>/dev/null)
    local git_stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

    # Default color for clean repo
    local git_color="%F{10}"
    local git_status_symbol=""
    local git_indicators=""

    # Check if repo has changes
    if [[ -n "$git_status" ]]; then
      # Count different types of changes
      local staged=$(echo "$git_status" | grep -E '^[MADRC]' | wc -l | tr -d ' ')
      local unstaged=$(echo "$git_status" | grep -E '^.[MADRC]' | wc -l | tr -d ' ')
      local untracked=$(echo "$git_status" | grep -E '\?\?' | wc -l | tr -d ' ')

      git_color="%F{11}"

      # More detailed status indicators with consistent spacing
      if [[ $staged -gt 0 ]]; then
        git_indicators="${git_indicators} %F{10}●${staged}%f "
      fi
      if [[ $unstaged -gt 0 ]]; then
        git_indicators="${git_indicators} %F{11}●${unstaged}%f "
      fi
      if [[ $untracked -gt 0 ]]; then
        git_indicators="${git_indicators} %F{8}●${untracked}%f "
      fi
    else
      git_status_symbol=" %F{10}✓%f"
    fi

    # Add ahead/behind indicators
    if [[ -n "$git_ahead" && "$git_ahead" != "0" ]]; then
      git_indicators="${git_indicators} %F{14}↑${git_ahead}%f "
    fi
    if [[ -n "$git_behind" && "$git_behind" != "0" ]]; then
      git_indicators="${git_indicators} %F{13}↓${git_behind}%f "
    fi

    # Add stash indicator
    if [[ "$git_stash_count" != "0" ]]; then
      git_indicators="${git_indicators} %F{6}≡${git_stash_count}%f "
    fi

    # Output the branch name and all indicators with consistent spacing
    echo -n "${git_color}‹${git_branch}›%f${git_status_symbol}${git_indicators}"
  fi
}

# Command execution time
zen_cmd_exec_time() {
  if [[ -v ZEN_THEME_SHOW_EXEC_TIME ]]; then
    if [ $ZEN_CMD_EXEC_TIME ]; then
      local hours=$(($ZEN_CMD_EXEC_TIME / 3600))
      local minutes=$((($ZEN_CMD_EXEC_TIME - $hours * 3600) / 60))
      local seconds=$(($ZEN_CMD_EXEC_TIME - $hours * 3600 - $minutes * 60))
      local time_str=""

      if [ $hours -gt 0 ]; then
        time_str="${hours}h${minutes}m${seconds}s"
      elif [ $minutes -gt 0 ]; then
        time_str="${minutes}m${seconds}s"
      else
        time_str="${seconds}s"
      fi

      echo "%F{8}took ${time_str}%f"
    fi
  fi
}

# Hooks for command execution time
preexec() {
  ZEN_CMD_START_TIME=$SECONDS
}

precmd() {
  if [ $ZEN_CMD_START_TIME ]; then
    ZEN_CMD_EXEC_TIME=$(($SECONDS - $ZEN_CMD_START_TIME))
    unset ZEN_CMD_START_TIME

    # Only show execution time for commands that take longer than 5 seconds
    if [ $ZEN_CMD_EXEC_TIME -lt 5 ]; then
      unset ZEN_CMD_EXEC_TIME
    fi
  fi
}

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
    echo -n "%F{4}%n"  # Blue for SSH
  else
    echo -n "%F{6}%n"  # Cyan for local
  fi

  echo -n "%F{8}@"

  # Hostname color changes based on SSH status
  if [[ "$ssh_status" == "ssh" ]]; then
    echo -n "%F{5}%m"  # Purple for SSH
  else
    echo -n "%F{12}%m"  # Light blue for local
  fi

  echo -n "%F{8}:"
  echo -n "%F{8}%~%f"
  echo -n " "

  # Git branch information with enhanced status
  echo -n "$(zen_git_status)"

  echo -n "${prompt_end}"

  # Prompt symbol changes color based on user privileges and last command status
  if [[ $UID -eq 0 ]]; then
    echo -n "%F{196}#%f "  # Red for root
  else
    echo -n "%(?.%F{214}.%F{1})$%f "  # Orange for normal user, red if last command failed
  fi
}

# Right Prompt
zen_get_rprompt() {
  # Command execution time
  local exec_time=$(zen_cmd_exec_time)
  if [[ -n "$exec_time" ]]; then
    echo -n "%F{8}${exec_time}%f "
  fi

  # Return code if non-zero with arrow symbol
  echo -n "%(?..%F{196}‹%?›%f ↵)"

  # Virtual environment indicator
  if [[ -v VIRTUAL_ENV ]]; then
    echo -n "%F{202} ["$(basename "$VIRTUAL_ENV")"]%f"
  fi

  # Time display if enabled
  if [[ -v ZEN_THEME_SHOW_TIME ]]; then
    echo -n "%F{8} [%D{%H:%M:%S}]%f"
  fi

  # SSH indicator
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    echo -n "%F{4} [SSH]%f"
  fi
}

export PROMPT='$(zen_get_prompt)'
export RPROMPT='$(zen_get_rprompt)'

# --- Helper functions (if they don't already exist) ---
# These provide defaults if the corresponding tools aren't installed

if ! (( $+functions[git_prompt_info] )); then
  function git_prompt_info() { echo "" }
fi

if ! (( $+functions[virtualenv_prompt_info] )); then
  function virtualenv_prompt_info() { echo "" }
fi

# ZSH Theme configuration for compatibility with plugins
ZSH_THEME_GIT_PROMPT_PREFIX="%F{220}% ‹"
ZSH_THEME_GIT_PROMPT_SUFFIX="›%f"
ZSH_THEME_GIT_PROMPT_DIRTY="%F{11}✗ "
ZSH_THEME_GIT_PROMPT_CLEAN="%F{10}✓ "

ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX="%F{202}% ["
ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX="]%f"
ZSH_THEME_VIRTUALENV_PREFIX=$ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX
ZSH_THEME_VIRTUALENV_SUFFIX=$ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX
