#!/bin/bash

# This script helps set up and push the iOS 18 optimized branch to GitHub

# Set your GitHub username here
GITHUB_USERNAME=""

# Function to check if GitHub username is set
check_username() {
  if [ -z "$GITHUB_USERNAME" ]; then
    echo "Please edit this script to set your GitHub username at the top of the file."
    exit 1
  fi
}

# Function to confirm action
confirm() {
  read -p "$1 [y/N]: " response
  case "$response" in
    [yY][eE][sS]|[yY]) 
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Function to set up GitHub remote
setup_remote() {
  # Check if remote already exists
  if git remote | grep -q "^origin$"; then
    echo "Remote 'origin' already exists."
    if confirm "Do you want to update it?"; then
      git remote remove origin
      git remote add origin "https://github.com/$GITHUB_USERNAME/HealthAI-2030.git"
      echo "Remote 'origin' updated."
    fi
  else
    git remote add origin "https://github.com/$GITHUB_USERNAME/HealthAI-2030.git"
    echo "Remote 'origin' added."
  fi
}

# Function to push to GitHub
push_to_github() {
  echo "Pushing to GitHub..."
  git push -u origin main
  
  # Create and push iOS 18 branch if not on main
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Also pushing branch '$CURRENT_BRANCH'..."
    git push -u origin "$CURRENT_BRANCH"
  fi
}

# Main execution
echo "iOS 18 Optimization GitHub Setup"
echo "================================"

# Check if this is a git repository
if [ ! -d .git ]; then
  echo "This is not a Git repository. Initializing..."
  git init
  git add .
  git commit -m "Initial commit with iOS 18 optimized codebase"
fi

# Check GitHub username
check_username

# Setup remote
setup_remote

# Push to GitHub if confirmed
if confirm "Do you want to push the repository to GitHub now?"; then
  push_to_github
  echo "Repository pushed to GitHub successfully!"
  echo "View your repository at: https://github.com/$GITHUB_USERNAME/HealthAI-2030"
else
  echo "You can push to GitHub later by running: git push -u origin main"
fi

echo ""
echo "Done! Your iOS 18 optimized codebase is ready for GitHub."
