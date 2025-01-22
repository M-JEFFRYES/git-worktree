############################################
############### Git Worktree ###############
############################################

function __determine_git_repo_root() {
    # These paths will work a) when we're already in a repo or b) when we're in a "worktree" repo's parent directory, with "main" containining the real repo
    local test_dirs=("" "main")
    
    for dir in "${(@)test_dirs}"; do
        if repo_root=$(/opt/homebrew/bin/git -C ./${dir} rev-parse --show-toplevel 2>&1); then
            echo "${repo_root}"
            break
        fi
        
    done
}

git() {
    /opt/homebrew/bin/git -C "$(__determine_git_repo_root)" $@

}

# Hide work_in_progress, as I don't use it and it makes it harder to access worktree
unfunction work_in_progress

function worktree() {
    local branch_name="${1}"
    local repo_root="$(__determine_git_repo_root)"
    local new_dir="${repo_root}/../${branch_name}"
    # Ensure local git repo is up to date
    git fetch --all
    # Create the worktree
    # If the branch already exists, just use it and check it out
    if  git rev-parse --verify "${branch_name}" &> /dev/null; then
        git worktree add "${new_dir}" "${branch_name}"
        /opt/homebrew/bin/git -C "${new_dir}" checkout "${branch_name}"
    else
        # Otherwise, create a new branch with the correct name and set up remote tracking
        local worktree_command=(git worktree add -b "${branch_name}" "${new_dir}")
        
        # If the branch exists on remote, track that...
        local remote_branch_name="origin/${branch_name}"
        if  git rev-parse --verify "${remote_branch_name}" &> /dev/null; then
            worktree_command+=("--track" "${remote_branch_name}")
        else
            # But if not, just use origin/main as the source (without tracking)
            worktree_command+=("--no-track" "origin/main")
        fi
        
        # git worktree add --track -b "${branch_name}" "${new_dir}" "${remote_tracking_branch}"
        # (set -x; "${worktree_command[@]}")
        "${worktree_command[@]}"
    fi
    # Move into the worktree directory
    cd "${new_dir}"
}

function _worktree() {
    local branches options
    # Get all remote branches, outputting their name only (without "origin/" prefix)
    branches="$(git branch -r --format="%(refname:lstrip=-1)")"

    # Convert the newline separated string into an array (use ${(@f)VAR} to split at new lines)
    set -A options "${(@f)branches}"
    
    compadd -M 'l:|=* r:|=*' ${options}
}

compdef _worktree worktree

function worktree-from-branch() {
    local branch_name="${1}"
    local source_branch="${2}"
    local repo_root="$(__determine_git_repo_root)"
    local new_dir="${repo_root}/../${branch_name}"

    # Ensure local git repo is up to date
    git fetch --all
    # Create the worktree
    # If the branch already exists, just use it and check it out
    if  git rev-parse --verify "${branch_name}" &> /dev/null; then
        git worktree add "${new_dir}" "${branch_name}"
        /opt/homebrew/bin/git -C "${new_dir}" checkout "${branch_name}"
    else
        # Otherwise, create a new branch with the correct name and set up remote tracking
        local worktree_command=(git worktree add -b "${branch_name}" "${new_dir}")
        
        # If the branch exists on remote, track that...
        local remote_branch_name="origin/${branch_name}"
        if  git rev-parse --verify "${remote_branch_name}" &> /dev/null; then
            worktree_command+=("--track" "${remote_branch_name}")
        else
            # But if not, just use origin/source_branch as the source (without tracking)
            worktree_command+=("--no-track" "origin/${source_branch}")
        fi
        
        # git worktree add --track -b "${branch_name}" "${new_dir}" "${remote_tracking_branch}"
        # (set -x; "${worktree_command[@]}")
        "${worktree_command[@]}"
    fi
    # Move into the worktree directory
    cd "${new_dir}"
}

function _worktree-from-branch() {
    local branches options
    # Get all remote branches, outputting their name only (without "origin/" prefix)
    branches="$(git branch -r --format="%(refname:lstrip=-1)")"

    # Convert the newline separated string into an array (use ${(@f)VAR} to split at new lines)
    set -A options "${(@f)branches}"
    
    compadd -M 'l:|=* r:|=*' ${options}
}

compdef _worktree-from-branch worktree-from-branch

function rm-worktree() {
    # Check if a worktree was provided
    local worktree_name="${1}"

    # Store the current directory
    local original_pwd="$(pwd)"
    
    local worktree_root="$(realpath $(__determine_git_repo_root)/../)"

    if [ -z "${worktree_name}" ]; then
        # If not, retrieve it from current directory (presumably within a worktree)
        local git_dir="$(git rev-parse --git-dir 2>&1)"
        # Check that we're inside a working tree
        if [[ "${git_dir}" == *"/worktrees/"* ]] ; then
            # Get the last part of git_dir - ie, the folder / worktree name
            worktree_name="$(echo "${git_dir}" | rev | cut -d/ -f1 | rev)"
        else
            echo "It appears that you are not inside a worktree. Please move to a worktree before running this command"
            return -1
        fi
    fi
    
    # Move into the worktree root so that there's no issue removing the worktree
    cd "${worktree_root}"

    # Remove the worktree
    git -C "${worktree_root}/main" worktree remove "${worktree_name}"

    # Move back to the original directory, if it still exists
    if [ -d "${original_pwd}" ]; then
        cd "${original_pwd}"
    fi
}

function _rm-worktree() {
    local worktrees options
    # Get all worktree names, excluding "main"
    worktrees="$(git worktree list | cut -d" " -f1 | rev | cut -d"/" -f1 | rev | grep -vi main)"

    # Convert the newline separated string into an array (use ${(@f)VAR} to split at new lines)
    set -A options "${(@f)worktrees}"
    
    compadd -M 'l:|=* r:|=*' ${options}
}

compdef _rm-worktree rm-worktree

############################################
########### End of Git Worktree ############
############################################