#!/usr/bin/env bash

function run_terraform_docs {
  local configuration="${1}"
  shift

  local arguments="${*}"

  ( # shellcheck disable=SC2164 # $path has already been tested
    cd "${configuration}"
    show_debug "working in ${configuration}"
    # shellcheck disable=SC2086 # $arguments does not need quoting
    terraform-docs ${arguments} . \
      | awk '/updated successfully$/ {sub( updated successfully$/,""); print}' \
      | while read -r file; do
        stage_document "${file}"
      done
  )
}

function stage_document {
  local configuration="${1}"
  local document="${2}"

  show_debug "staging ${configuration}/${document}"

}
