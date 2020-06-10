#!/usr/bin/env bash

set -ex

branch_name=update-${1:-$(date +"%Y-%m-%d")}
current_versions_file=./ci-generator/unity_versions.yml
old_versions_file=./ci-generator/unity_versions.old.yml
ci_file=./.gitlab-ci.yml

function update_local_repo() {
  git checkout master
  git pull
}

function create_new_update_branch() {
  git checkout -b $branch_name || true
  git checkout $branch_name
}

function generate_ci_file() {
    docker-compose run --rm generate
    git add $ci_file
    git status
    git commit -m "docker-compose run --rm generate"
}

function move_current_versions_to_old_file() {
    echo '' >> $old_versions_file
    cat $current_versions_file >> $old_versions_file
    echo '' > $current_versions_file
    git add $old_versions_file
    git add $current_versions_file
    git status
    git commit -m "Move unity versions to old file"
}

function lint_gitlab_ci_file() {
  cat $ci_file | docker run --rm -i gableroux/gitlab-ci-lint
}

function clean_current_version_file_if_not_empty() {
  if [ -s $current_versions_file ]; then
    echo "Cleaning $current_versions_file"
    move_current_versions_to_old_file
    lint_gitlab_ci_file
  fi
}

function fetch_new_versions_from_unity_endpoint() {
  docker-compose run --rm update
  cat $current_versions_file
  if [ -s $current_versions_file ]; then
    git add $current_versions_file
    git status
    git commit -m "docker-compose run --rm update"
    echo "Committed new versions to $current_versions_file"
    generate_ci_file
  else
    echo "No new version found, keeping $current_versions_file empty"
  fi
}

update_local_repo
create_new_update_branch
clean_current_version_file_if_not_empty
fetch_new_versions_from_unity_endpoint
