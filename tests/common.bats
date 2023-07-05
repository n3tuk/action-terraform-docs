#!/usr/bin/env bats

bats_load_library "bats-support"
bats_load_library "bats-assert"

load "helpers/common"

setup() {
  set_environment_variables
}

@test "start_group() outputs correct format for GitHub Workflows" {
  source lib/common.sh
  run start_group test
  assert_output --partial "::group::test"
  assert_success
}

@test "end_group() outputs correct format for GitHub Workflows" {
  source lib/common.sh
  run end_group
  assert_output "::endgroup::"
  assert_success
}

@test "show_debug() outputs correct format for GitHub Workflows" {
  source lib/common.sh
  run show_debug test
  assert_output "::debug::test"
  assert_success
}

@test "show_error() outputs correct format for GitHub Workflows" {
  source lib/common.sh
  run show_error test
  assert_output "::error::test"
  assert_success
}

@test "exit_error() outputs correct format for GitHub Workflows with exit status" {
  source lib/common.sh
  run exit_error test
  assert_output "::error::test"
  assert_failure
}

@test "check_variable() successfully finds WORKING_DIRECTORY variable" {
  refute_empty "${WORKING_DIRECTORY}"
  source lib/common.sh
  run check_variable WORKING_DIRECTORY RECURSIVE
  assert_success
}

@test "check_variables() successfully finds RECURSIVE variable with other variables" {
  refute_empty "${WORKING_DIRECTORY}"
  refute_empty "${RECURSIVE}"
  source lib/common.sh
  run check_variables WORKING_DIRECTORY RECURSIVE
  assert_success
}

@test "check_variable() fails on missing WORKING_DIRECTORY variable" {
  unset WORKING_DIRECTORY
  assert_empty "${WORKING_DIRECTORY}"
  source lib/common.sh
  run check_variable WORKING_DIRECTORY
  assert_output --partial "::error::"
  assert_output --partial "WORKING_DIRECTORY"
  assert_failure
}

@test "check_variables() fails on missing FAIL_ON_DIFF variable among others" {
  unset FAIL_ON_DIFF
  refute_empty "${WORKING_DIRECTORY}"
  refute_empty "${RECURSIVE}"
  assert_empty "${FAIL_ON_DIFF}"
  source lib/common.sh
  run check_variables WORKING_DIRECTORY RECURSIVE FAIL_ON_DIFF
  assert_output --partial "::error::"
  assert_output --partial "FAIL_ON_DIFF"
  assert_failure
}

@test "check_command() successfully finds bash command" {
  source lib/common.sh
  run check_command bash
  assert_success
}

@test "check_commands() successfully finds bash and sh commands" {
  source lib/common.sh
  run check_commands bash sh
  assert_success
}

@test "check_command() fails on missing does-not-exist command" {
  source lib/common.sh
  run check_command does-not-exist
  assert_output --partial "::error::"
  assert_output --partial "does-not-exist"
  assert_failure
}

@test "check_commands() fails on missing does-not-exist command" {
  source lib/common.sh
  run check_commands bash sh does-not-exist
  assert_output --partial "::error::"
  assert_output --partial "does-not-exist"
  assert_failure
}
