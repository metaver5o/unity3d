#!/usr/bin/env bash

set -ex
source scripts/commands.sh

update_local_repo
create_new_update_branch
clean_current_version_file_if_not_empty
fetch_new_versions_from_unity_endpoint
