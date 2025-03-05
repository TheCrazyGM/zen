# Installation Instructions for Zen Theme

## Prerequisites

- [Oh-My-Zsh](https://ohmyz.sh/) installed
- Git (optional, for cloning the repository)

## Installation Methods

### Method 1: Manual Installation

1. Download the theme file:

   ```bash
   curl -o ~/.oh-my-zsh/themes/zen.zsh-theme https://raw.githubusercontent.com/thecrazygm/zen/main/zen/zen.zsh-theme
   ```

2. Set the theme in your `~/.zshrc` file:

   ```bash
   ZSH_THEME="zen"
   ```

3. Apply the changes:

   ```bash
   source ~/.zshrc
   ```

### Method 2: Git Clone

1. Clone the repository:

   ```bash
   git clone https://github.com/thecrazygm/zen.git ~/.oh-my-zsh/custom/themes/zen
   ```

2. Create a symbolic link to the theme file:

   ```bash
   ln -s ~/.oh-my-zsh/custom/themes/zen/zen/zen.zsh-theme ~/.oh-my-zsh/themes/zen.zsh-theme
   ```

3. Set the theme in your `~/.zshrc` file:

   ```bash
   ZSH_THEME="zen"
   ```

4. Apply the changes:

   ```bash
   source ~/.zshrc
   ```

## Configuration Options

Add any of these to your `~/.zshrc` file to customize your Zen theme experience:

```bash
# Show current time in prompt
export ZEN_THEME_SHOW_TIME=true

# Use two-line prompt format
export ZEN_THEME_TWO_LINES=true

# Show execution time for commands that take longer than 5 seconds
export ZEN_THEME_SHOW_EXEC_TIME=true
```

## Troubleshooting

- If you encounter any issues with the Git status indicators, make sure you have Git installed and accessible in your PATH.
- For issues with the SSH detection, verify that your SSH environment variables are properly set.
- If command execution time tracking isn't working, ensure that your Zsh version is up to date (5.0.8 or newer recommended).
