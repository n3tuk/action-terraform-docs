#!/usr/bin/env bash

function find_configurations {
  local path=${1}
  local recursive=${2}

  if [[ ! -d ${path} ]]; then
    exit_error "The path '${path}' is not a directory or could not be found"
  fi

  ( # shellcheck disable=SC2164 # $path has already been tested
    cd "${path}"
    if [[ ${recursive} == "true" ]]; then
      find . \
        -type f \
        -name '*.tf' -and \
        -not \( -path '*.terraform/modules/*' -or -path '*.external_modules/*' \) \
        -printf '%h\n' \
        | sort \
        | uniq \
        | sed -e 's|^\./||g'
    else
      # Use -quit to print one directory entry and exit, assuming there is a .tf
      # file in that directory, as we're only testing the one directory
      find . \
        -maxdepth 1 \
        -type f \
        -name '*.tf' \
        -printf '%h\n' \
        -quit \
        | sed -e 's|^\./||g'
    fi
  ) | sort | uniq
}
