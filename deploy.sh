#!/usr/bin/env bash

set -e

repo_dir="$( cd "$( dirname "$0" )" && pwd )"

(
    cd "$repo_dir"

    branch_name="$(git symbolic-ref HEAD 2>/dev/null)" ||
    branch_name="(unnamed branch)"     # detached HEAD

    branch_name=${branch_name##refs/heads/}

    if [ "${branch_name}" != "hugo" ]; then
        echo "Can only publish from the main \"hugo\" branch"
        exit 1
    fi

    if [ "$(git status -s)" ]; then
        echo "The working directory is dirty. Please commit any pending changes."
        exit 1;
    fi

    echo "Deleting old publication"
    rm -rf public
    mkdir public
    git worktree prune
    rm -rf .git/worktrees/public/

    echo "Checking out master branch into public"
    git worktree add -B master public origin/master

    echo "Removing existing files"
    rm -rf public/*

    echo "Generating site"
    hugo

    msg="rebuilding site $(date)"
    if [ -n "$*" ]; then
        msg="$*"
    fi
    git commit -m "$msg"

    echo "Updating master branch"
    (
        cd public
        git add --all
        git commit -m "$msg"

    )

    echo "Pushing to github"
    git push --all
)
