#!/usr/bin/env bats

# Set up the standard environment variables which will normally be provided by
# the GitHub Action configuration
function set_environment_variables {
  # General directory and configuration settings
  WORKING_DIRECTORY="terraform\nmodules"
  CONFIG=""
  RECURSIVE="false"
  export WORKING_DIRECTORY CONFIG RECURSIVE

  # Default settings for output configurations (which will be overridden by
  # the CONFIG_FILE variable, if set) for terraform-docs
  OUTPUT_FORMAT="markdown table"
  OUTPUT_MODE="inject"
  INDENT="2"
  OUTPUT_TEMPLATE="<!-- BEGIN_TF_DOCS -->\n{{ .Content }}\n<!-- END_TF_DOCS -->"
  OUTPUT_FILE="README.md"
  LOCKFILE="true"
  export OUTPUT_FORMAT OUTPUT_MODE INDENT OUTPUT_TEMPLATE OUTPUT_FILE LOCKFILE

  # Default settings for dealing with repository difference detection
  FAIL_ON_DIFF="false"
  SHOW_ON_DIFF="true"
  export FAIL_ON_DIFF SHOW_ON_DIFF

  # Default settings for git configuration and whether to run git staging,
  # committing, and pushing back to the repository on changes
  GIT_PUSH="false"
  GIT_NAME="github-actions[bot]"
  GIT_EMAIL="41898282+github-actions[bot]@users.noreply.github.com"
  GIT_TITLE="Syncing changes made by terraform-docs"
  GIT_BODY=""
  export GIT_PUSH GIT_NAME GIT_EMAIL GIT_TITLE GIT_BODY
}

# Create the required files for validating testing of Terraform configuration
# layouts and terraform-docs configuration files
function create_test_files {
  local base=${1}
  shift

  show_debug "create_test_files() base=${base} files=${*}"

  for file in "${@}"; do
    # Make sure the parent directory is created first
    mkdir -p "${base}/$(dirname "${file}")"
    touch "${base}/${file}"
    echo "${file}" >>"${base}/.test-files"
  done
}

# Remove the created files for validating testing of various directory
# structures and configurations
function clean_all_files {
  find "${1}" -type f -delete \
    \( -name '*.tf' -or -name '.terraform-docs.yaml' \)
}

# Remove the created files for validating testing of various directory
# structures and configurations
function clean_test_files {
  local base=${1}

  (
    cd "${base}" || exit
    test -e .test-files || exit
    while read -r file <.test-files; do
      rm -f "${file}"
      # Attempt to clean any directories created alongside the files
      rmdir --ignore-fail-on-non-empty --parents "$(dirname "${file}")"
    done
  )
}

function assert_empty {
  assert [ -z "${1}" ]
}

function refute_empty {
  assert [ ! -z "${1}" ]
}
