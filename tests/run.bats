#!/usr/bin/env bats

bats_load_library "bats-support"
bats_load_library "bats-assert"

load "helpers/common"
load "helpers/terraform-docs"

setup() {
  set_environment_variables
  test_dir=$(mktemp --directory --suffix=-bats)
}

teardown() {
  rm -rf "${test_dir}"
}

@test "run_terraform_docs() calls as expected" {
  source lib/common.sh
  source lib/run.sh

  run run_terraform_docs "${test_dir}" "--config ${test_dir}/.terraform-docs.yaml"
  assert_success
}
