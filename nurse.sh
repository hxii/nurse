#!/bin/bash

SCRIPT_VERSION="0.1.0"
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

### UTILS

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

error() {
  echo -e "${RED}Error: $1${NC}"
}

success() {
  echo -e "${GREEN}Success: $1${NC}"
}

warning() {
  echo -e "${YELLOW}Warning: $1${NC}"
}

print_header() {
  printf "\n╭───────────────────────────────╮\n│ %-29s │\n╰───────────────────────────────╯\n" "$1"
}

verify_command() {
  local command_name="$1"
  if command -v "$command_name" &>/dev/null; then
    success "  $command_name is available ($(${command_name} --version 2>/dev/null))"
  else
    error "  $command_name is NOT available"
  fi
}

### NURSE

echo -e "${GREEN}nurse $SCRIPT_VERSION - $CURRENT_DATE${NC}"

### SYSTEM INFORMATION

# Function to print machine info
print_machine_info() {
  echo "  Machine: $(sysctl -n hw.model) $(sysctl -n machdep.cpu.brand_string) $(uname -m)"
}

# Function to print OS version
print_os_version() {
  echo "  OS: macOS $(sw_vers -productVersion)"
}

# Function to print OS updates
print_updates() {
  updates=$(softwareupdate -l 2>&1 | grep "\*.*" || echo "No updates available")
  echo "  Updates: $updates"
}

# Get xcode version and install path
print_xcode() {
  if command -v xcode-select &>/dev/null; then
    echo "  Xcode CLT: $(xcode-select --version) $(xcode-select --print-path)"
  fi
}

# Function to print username and sudo privileges
print_user_info() {
  user=$(whoami)
  if sudo -n true 2>/dev/null; then
    sudo_status="Yes"
  else
    sudo_status="No"
  fi
  echo "  Username: $user"
  echo "  Sudo Privileges: $sudo_status"
}

# Print the system information
print_header "System"
print_machine_info &
print_os_version &
print_updates &
print_xcode &
print_user_info &

# Wait for all background processes to finish
wait

### SHELL INFORMATION

# Function to print the current shell
print_shell_info() {
  shell_name=$(basename "$SHELL")
  echo "  Shell: $shell_name"
}

# Function to check for common shell frameworks
print_shell_frameworks() {
  omz_status="No"
  omf_status="No"
  starship_status="No"

  [[ -d "$HOME/.oh-my-zsh" ]] && omz_status="Yes"
  [[ -d "$HOME/.config/omf" ]] && omf_status="Yes"
  [[ -f "$(which starship 2>/dev/null)" ]] && starship_status="Yes"

  echo "  Shell Frameworks:"
  echo "    Oh-My-Zsh: $omz_status"
  echo "    Oh-My-Fish: $omf_status"
  echo "    Starship: $starship_status"
}

# Function to list loaded shell files
print_loaded_shell_files() {
  local shell
  shell=$(basename "$SHELL")

  print_header "Loaded Shell Files"

  case "$shell" in
  bash)
    local files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile")
    for file in "${files[@]}"; do
      if [ -f "$file" ]; then
        echo "  $file"
        grep -E 'source|\. ' "$file" | while read -r line; do
          echo "    $line"
        done
      else
        echo "  $file (not found)"
      fi
    done
    ;;

  zsh)
    local files=("$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zlogin" "$HOME/.zshenv")
    for file in "${files[@]}"; do
      if [ -f "$file" ]; then
        echo "  $file"
        grep -E 'source|\. ' "$file" | while read -r line; do
          echo "    $line"
        done
      else
        echo "  $file (not found)"
      fi
    done
    ;;

  fish)
    local config_file="$HOME/.config/fish/config.fish"
    local conf_d_dir="$HOME/.config/fish/conf.d/"
    if [ -f "$config_file" ]; then
      echo "  $config_file"
      grep -E 'source|include ' "$config_file" | while read -r line; do
        echo "    $line"
      done
    else
      echo "  $config_file (not found)"
    fi

    if [ -d "$conf_d_dir" ]; then
      echo "  $conf_d_dir/"
      find "$conf_d_dir" -type f -exec echo "    {}" \;
    else
      echo "  $conf_d_dir (not found)"
    fi
    ;;

  *)
    echo "  Unsupported shell: $shell"
    ;;
  esac
}

# Function to print PATH variable broken down
print_path_variable() {
  echo "  PATH:"
  echo "$PATH" | tr ':' '\n' | sed 's/^/    - /'
}

# Print environment information in correct order
print_header "Environment"
print_shell_info
print_shell_frameworks
print_loaded_shell_files
print_path_variable

### APPS AND UTILS
check_important_executables() {

  for exe in brew pipx forter git docker aws pyenv keyring; do
    verify_command "$exe"
  done
}

print_header "Apps and Utilities"
check_important_executables

### PYTHON INFORMATION

# Function to check Python versions installed natively
print_native_python_versions() {
  echo "  Native Python Versions:"
  native_python_versions=$(echo /usr/bin/python* /usr/local/bin/python* | tr ' ' '\n' | grep -E 'python[0-9.]*$' | sort -u)

  if [ -z "$native_python_versions" ]; then
    echo "    None found"
  else
    for version in $native_python_versions; do
      local real_path
      real_path=$(realpath "$version")
      echo "    $version: $($version --version 2>&1) ($real_path)"
    done
  fi
}

# Function to check Python versions managed by pyenv
print_pyenv_python_versions() {
  if command -v pyenv &>/dev/null; then
    echo "  pyenv Python Versions:"
    pyenv_versions=$(pyenv versions --bare)
    if [ -z "$pyenv_versions" ]; then
      echo "    None found"
    else
      echo "$pyenv_versions" | while read -r version; do
        echo "    $version"
      done
    fi
  else
    echo "  pyenv is not installed"
  fi
}

# Function to check Python versions managed by conda
print_conda_python_versions() {
  if command -v conda &>/dev/null; then
    echo "  Conda Python Versions:"
    conda_versions=$(conda info --envs | awk '/^\s*(base|.*envs.*)\s*/{print $1}' | xargs -I{} conda run -n {} python --version 2>/dev/null | sort -u)
    if [ -z "$conda_versions" ]; then
      echo "    None found"
    else
      echo "$conda_versions" | while read -r version; do
        echo "    $version"
      done
    fi
  else
    echo "  Conda is not installed"
  fi
}

# Function to check Python versions installed via Homebrew
print_brew_python_versions() {
  if command -v brew &>/dev/null; then
    echo "  Homebrew Python Versions:"
    brew_versions=$(brew list --versions | grep -E '^python@([0-9.]+)?' | awk '{print $2}')
    if [ -z "$brew_versions" ]; then
      echo "    None found"
    else
      for version in $brew_versions; do
        echo "    python: $version"
      done
    fi
  else
    echo "  Homebrew is not installed"
  fi
}

# Function to check Python versions managed by mise
print_mise_python_versions() {
  if command -v mise &>/dev/null; then
    echo "  mise Python Versions:"
    mise_versions=$(mise list python | awk '{print $2}')
    if [ -z "$mise_versions" ]; then
      echo "    None found"
    else
      for version in $mise_versions; do
        echo "    python: $version"
      done
    fi
  else
    echo "  mise is not installed"
  fi
}

# Function to check Python versions managed by asdf
print_asdf_python_versions() {
  if command -v asdf &>/dev/null; then
    echo "  asdf Python Versions:"
    asdf_versions=$(asdf list python)
    if [ -z "$asdf_versions" ]; then
      echo "    None found"
    else
      echo "$asdf_versions" | while read -r version; do
        echo "    $version"
      done
    fi
  else
    echo "  asdf is not installed"
  fi
}

# Print Python versions information
print_header "Python Versions"
print_native_python_versions
print_pyenv_python_versions
print_conda_python_versions
print_brew_python_versions
print_mise_python_versions
print_asdf_python_versions

### PIPX INFORMATION

print_pipx_information() {
  if command -v pipx &>/dev/null; then
    pipx list --verbose 2>&1 | while read -r line; do
      echo "  $line"
    done
  else
    echo "pipx not available"
  fi
}

print_header "Pipx"
print_pipx_information

### BREW INFORMATION

print_brew_config() {
  if command -v brew &>/dev/null; then
    brew config -v | while read -r line; do
      echo "  $line"
    done
  fi
}

print_header "Brew Information"
print_brew_config

### BREW LIST
print_brew_list() {
  if command -v brew &>/dev/null; then
    brew list --versions | while read -r item; do
      echo "  $item"
    done
  fi
}

print_header "Brew Formulae and Casks"
print_brew_list

### REPOSITORIES

print_repo_info() {
  local repo_path="$1"
  local branch="$2"
  local status="$3"
  local last_pull="$4"

  echo -e "\nRepository: $repo_path"
  echo -e "Branch:     $branch"
  echo -e "Status:     $status"
  echo -e "Last Pull:  $last_pull"
}

check_git_repo() {
  local repo_dir="$1"

  # Check if the directory contains a .git folder
  if [ ! -d "$repo_dir/.git" ]; then
    echo -e "\n$repo_dir is not a Git repository"
    return
  fi

  # Change to the repository directory
  cd "$repo_dir" || return

  # Get current branch
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

  # Get status
  local status
  status=$(git status --short 2>/dev/null)
  local num_untracked
  local num_deleted
  local num_modified

  num_untracked=$(echo "$status" | grep -cE '^\s+\?\?')
  num_deleted=$(echo "$status" | grep -cE '^\s+D')
  num_modified=$(echo "$status" | grep -cE '^\s+M')

  if [ "$num_untracked" -eq 0 ] && [ "$num_deleted" -eq 0 ] && [ "$num_modified" -eq 0 ]; then
    status_summary="No changes"
  else
    status_summary=""
    [ "$num_untracked" -gt 0 ] && status_summary+="$num_untracked untracked file(s), "
    [ "$num_deleted" -gt 0 ] && status_summary+="$num_deleted deleted file(s), "
    [ "$num_modified" -gt 0 ] && status_summary+="$num_modified modified file(s)"
    # status_summary=$(echo "$status_summary" | sed 's/, $//') # Remove trailing comma
    status_summary=${status_summary//, $/}
  fi

  # Get last pull date
  local last_pull_date
  last_pull_date=$(git reflog show --date=short | grep 'pull' | head -n 1 | awk '{print $1, $2}' 2>/dev/null)
  local last_pull_info
  if [ -n "$last_pull_date" ]; then
    last_pull_info="Pulled on: $last_pull_date"
  else
    last_pull_info="Never pulled"
  fi

  # Check Python executable location
  local python_path
  python_path=$(which python 2>/dev/null)

  # Determine if it's part of a virtual environment
  local venv_status="No virtual environment detected"
  if [ -n "$python_path" ]; then
    # Check if the path is likely to be from a virtual environment
    if [[ "$python_path" == *"/venv/"* || "$python_path" == *"/.venv/"* ]]; then
      venv_status="Python in virtual environment: $python_path"
    else
      venv_status="Python executable: $python_path"
    fi
  fi

  # Output repository information
  local repo_path
  #repo_path=$(echo "$repo_dir" | sed "s|$HOME|~|")
  repo_path="${repo_dir//$HOME/~}"

  print_repo_info "$repo_path" "$branch" "$status_summary" "$last_pull_info"
  echo -e "Virtual Env: $venv_status"

  # Return to the original directory
  cd - >/dev/null || return
}

# Function to check all Git repositories under ~/dev/
check_git_repositories() {
  local dev_dir="$HOME/dev"

  print_header "Repositories"

  # Find directories with a .git folder and process them
  find "$dev_dir" -type d -name ".git" | while read -r git_dir; do
    local repo_dir
    repo_dir=$(dirname "$git_dir")
    check_git_repo "$repo_dir"
  done
}

# Call the function to check Git repositories
check_git_repositories
