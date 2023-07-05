#!/usr/bin/env bats

bats_load_library "bats-support"
bats_load_library "bats-assert"

load "helpers/common"

setup() {
  set_environment_variables
  test_dir=$(mktemp --directory --suffix=-bats)
}

teardown() {
  rm -rf "${test_dir}"
}

@test "find_configurations() search within single directory without recursion" {
  source lib/common.sh
  source lib/search.sh

  create_test_files \
    "${test_dir}" \
    terraform/{main,terraform}.tf \
    terraform/.terraform/modules/example-{one,two}/{main,terraform}.tf

  run find_configurations "${test_dir}/terraform" false
  assert_line "."
  refute_line "terraform/.terraform/modules/example-one"
  refute_line "terraform/.terraform/modules/example-two"
  assert_success
}

@test "find_configurations() search within multiple directories without recursion" {
  source lib/common.sh
  source lib/search.sh

  create_test_files \
    "${test_dir}" \
    terraform/{main,terraform}.tf \
    terraform/.terraform/modules/example-{one,two}/{main,terraform}.tf \
    modules/test-{one,two}/{main,terraform}.tf

  run find_configurations "${test_dir}/terraform" false
  assert_line "."
  refute_line "terraform/.terraform/modules/example-one"
  refute_line "terraform/.terraform/modules/example-two"
  assert_success
}

@test "find_configurations() search within empty directory without recursion" {
  source lib/common.sh
  source lib/search.sh

  create_test_files \
    "${test_dir}" \
    terraform/{main,terraform}.tf

  run find_configurations "${test_dir}" false
  refute_output --partial '::error::'
  refute_line "."
  refute_line "terraform"
  assert_success
}

@test "find_configurations() searches across multiple paths with recursion" {
  source lib/common.sh
  source lib/search.sh

  create_test_files \
    "${test_dir}" \
    terraform/{main,terraform}.tf \
    terraform/.terraform/modules/example-{one,two}/{main,terraform}.tf \
    modules/test-{one,two}/{main,terraform}.tf

  run find_configurations "${test_dir}" true
  refute_line "."
  assert_line "terraform"
  refute_line "terraform/.terraform/modules/example-one"
  refute_line "terraform/.terraform/modules/example-two"
  assert_line "modules/test-one"
  assert_line "modules/test-two"
  assert_success
}

@test "find_configurations() searches ignore .external_modules" {
  source lib/common.sh
  source lib/search.sh

  create_test_files \
    "${test_dir}" \
    {main,terraform}.tf \
    .external_modules/example-three/{main,terraform}.tf \
    modules/test-{one,two}/{main,terraform}.tf \
    modules/test-{one,two}/.external_modules/example-{four,five}/{main,terraform}.tf

  run find_configurations "${test_dir}" true
  assert_line "."
  refute_line ".external_modules/example-three"
  assert_line "modules/test-one"
  refute_line "modules/test-one/.external_modules/example-four"
  refute_line "modules/test-one/.external_modules/example-five"
  assert_line "modules/test-two"
  refute_line "modules/test-two/.external_modules/example-four"
  refute_line "modules/test-two/.external_modules/example-five"
  assert_success
}

@test "find_configurations() searches invalid path" {
  source lib/common.sh
  source lib/search.sh

  run find_configurations "${test_dir}/terraform" false
  assert_output --partial '::error::'
  refute_line "."
  refute_line "terraform"
  assert_failure
}

@test "find_configurations() searches empty repository" {
  source lib/common.sh
  source lib/search.sh

  run find_configurations "${test_dir}" true
  refute_output --partial '::error::'
  refute_line "."
  assert_success
}
