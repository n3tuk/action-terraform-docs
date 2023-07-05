#!/usr/bin/env bats

bats_load_library "bats-support"
bats_load_library "bats-assert"

load "helpers/common"

setup() {
  set_environment_variables

  test_dir=$(mktemp --directory --suffix=-bats)
  export GITHUB_WORKSPACE="${test_dir}"
}

teardown() {
  rm -rf "${test_dir}"
}

@test "find_config_file() finds configuration config file as preferred" {
  source lib/common.sh
  source lib/arguments.sh

  create_test_files \
    "${test_dir}" \
    {,modules/,modules/mod-one/}.terraform-docs.yaml

  run find_config_file modules modules/mod-one .terraform-docs.yaml
  assert_output "modules/mod-one/.terraform-docs.yaml"
  refute_output "modules/.terraform-docs.yaml"
  refute_output ".terraform-docs.yaml"
  assert_success
}

@test "build_settings() provides --config file as only setting when present" {
  source lib/common.sh
  source lib/arguments.sh

  create_test_files \
    "${test_dir}" \
    {,modules/,modules/mod-one/}.terraform-docs.yaml

  run build_settings modules modules/mod-one .terraform-docs.yaml
  assert_output "--config ${test_dir}/modules/mod-one/.terraform-docs.yaml"
  assert_success
}

@test "find_config_file() finds base config file as first fallback" {
  source lib/common.sh
  source lib/arguments.sh

  create_test_files \
    "${test_dir}" \
    {,modules/}.terraform-docs.yaml

  run find_config_file modules modules/mod-one .terraform-docs.yaml
  refute_output "modules/mod-one/.terraform-docs.yaml"
  assert_output "modules/.terraform-docs.yaml"
  refute_output ".terraform-docs.yaml"
  assert_success
}

@test "find_config_file() finds default config file as second fallback" {
  source lib/common.sh
  source lib/arguments.sh

  create_test_files \
    "${test_dir}" \
    .terraform-docs.yaml

  run find_config_file modules modules/mod-one .terraform-docs.yaml
  refute_output "modules/mod-one/.terraform-docs.yaml"
  refute_output "modules/.terraform-docs.yaml"
  assert_output ".terraform-docs.yaml"
  assert_success
}

@test "find_config_file() finds one config file in three references" {
  source lib/common.sh
  source lib/arguments.sh

  create_test_files \
    "${test_dir}" \
    .terraform-docs.yaml

  run find_config_file . . .terraform-docs.yaml
  assert_output ".terraform-docs.yaml"
  assert_success
}

@test "find_config_file() finds no default config file" {
  source lib/common.sh
  source lib/arguments.sh

  create_test_files \
    "${test_dir}" \
    {modules/,modules/mod-one/}.terraform-docs.yaml

  run find_config_file terraform terraform .terraform-docs.yaml
  refute_output "modules/mod-one/.terraform-docs.yaml"
  refute_output "modules/.terraform-docs.yaml"
  refute_output "terraform/.terraform-docs.yaml"
  refute_output ".terraform-docs.yaml"
  assert_success
}

@test "build_settings() provides no --config file when none present" {
  source lib/common.sh
  source lib/arguments.sh

  create_test_files \
    "${test_dir}" \
    {modules/,modules/mod-one/}.terraform-docs.yaml

  run build_settings terraform terraform .terraform-docs.yaml
  refute_output --partial "--config ${test_dir}/.terraform-docs.yaml"
  assert_success
}

@test "build_settings() sets the format to markdown table by default" {
  source lib/common.sh
  source lib/arguments.sh

  run build_settings terraform terraform .terraform-docs.yaml
  refute_output --partial "--config .terraform-docs.yaml"
  refute_output --partial "--config terraform/.terraform-docs.yaml"
  assert_output --partial "markdown table"
  assert_output --partial "--indent 2"
  refute_output --partial "json"
  assert_success
}

@test "build_settings() sets the format to json on override, bypassing --indent" {
  source lib/common.sh
  source lib/arguments.sh

  # shellcheck disable=SC2030 # override specifically for this test
  export OUTPUT_FORMAT="json"

  run build_settings terraform terraform .terraform-docs.yaml
  refute_output --partial "--config .terraform-docs.yaml"
  refute_output --partial "--config terraform/.terraform-docs.yaml"
  refute_output --partial "markdown table"
  assert_output --partial "json"
  refute_output --partial "--indent 2"
  assert_success
}

@test "build_settings() sets the defaults for --mode, --lockfile, and --output-file" {
  source lib/common.sh
  source lib/arguments.sh

  run build_settings terraform terraform .terraform-docs.yaml
  refute_output --partial "--config terraform/.terraform-docs.yaml"
  assert_output --partial "--mode inject"
  assert_output --partial "--lockfile"
  assert_output --partial "--output-file README.md"
  assert_success
}

@test "build_settings() sets disables --output-file when --output-mode is print" {
  source lib/common.sh
  source lib/arguments.sh

  # shellcheck disable=SC2030 # override specifically for this test
  export OUTPUT_MODE="print"

  run build_settings terraform terraform .terraform-docs.yaml
  refute_output --partial "--config terraform/.terraform-docs.yaml"
  refute_output --partial "--mode inject"
  assert_output --partial "--mode print"
  refute_output --partial "--output-file README.md"
  assert_success
}
