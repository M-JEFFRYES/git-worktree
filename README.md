# git-worktree

This repo provides git repo management tools to aide developer flow.

## Installation
1. Clone this repo to local machine
2. Update the shell configuration file, add the lines below:
  1. export GWT="path to git repo"
  2. source $GWT/git-worktree.sh

## Usage
### Repo set up
1. Create folder for repo
2. cd into repo
3. git clone "remote git repo" main

### Worktree from main
1. cd to repo parent dir
2. worktree "branch-name"

### Worktree from specified branch
1. cd to repo parent dir
2. worktree-from-branch "branch-name" "branch-to-stem-from"

### Remove worktree
1. cd to repo parent dir
2. rm-worktree-from-branch "branch-name-to-remove"
