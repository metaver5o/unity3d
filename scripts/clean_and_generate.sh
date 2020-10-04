#!/usr/bin/env bash

set -ex
source scripts/commands.sh

clean_current_version_file_if_not_empty
generate_ci_file
