#!/usr/bin/env bats
load 'libs/bats-support/load' # https://github.com/ztombol/bats-support
load 'libs/bats-assert/load' # https://github.com/ztombol/bats-assert
load 'libs/bats-file/load'

setup() {
    if [ "${BATS_TEST_NUMBER}" = 1 ];then
        echo "# ----- $(basename "${BATS_TEST_FILENAME}") ----- " >&3
    fi

    # Make a tmp directory for this specific test, copy in the install script,
    # and cd into it.
    # This directory is cleaned up on test teardown.
    ROOT_DIR="${BATS_TEST_DIRNAME}/.."
    TEST_DIR=$(temp_make)
    cp install.sh "${TEST_DIR}/"
    cd "${TEST_DIR}" || exit # fail the test if we can't enter this directory
}

teardown() {
  temp_del "${TEST_DIR}"
}

@test "install.bats file passes shellcheck" {
  if [ "${RUNNING_IN_CI}" -eq 1 ]; then
    skip "shellcheck on ubuntu cannot handle a bats file, so we skip it by setting RUNNING_IN_CI to 1"
  fi
  run which shellcheck # `brew install shellcheck` if this test fails
  refute_output ""

  run shellcheck "${BATS_TEST_FILENAME}"
  assert_success
  assert_output ""
}

@test "install script passes shellcheck" {
  run which shellcheck # `brew install shellcheck` if this test fails
  refute_output ""

  run shellcheck install.sh
  assert_success
  assert_output ""
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Guardrails
@test "install script is executable" {
  # since we adjust our location in test setup, change directories back to
  # the root of this repo (hardcoded).
  cd "${ROOT_DIR}"
  assert_file_executable "install.sh"
}

@test "fails with error when run outside git repo" {
  run "./install.sh"
  assert_failure
  assert_output --partial "git repo"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Simple git repo behavior tests
@test "properly installs commit-msg if available" {
  git init
  cp "${ROOT_DIR}/commit-msg" .

  run "./install.sh"
  assert_success

  assert_symlink_to "$(realpath commit-msg)" ".git/hooks/commit-msg"
}

@test "properly indempotent" {
  git init
  cp "${ROOT_DIR}/commit-msg" .

  run "./install.sh"
  assert_success
  assert_symlink_to "$(realpath commit-msg)" ".git/hooks/commit-msg"

  run "./install.sh"
  assert_success
  assert_symlink_to "$(realpath commit-msg)" ".git/hooks/commit-msg"

  rm ".git/hooks/commit-msg"
  assert_not_symlink_to "$(realpath commit-msg)" ".git/hooks/commit-msg"
  run "./install.sh"
  assert_success
  assert_symlink_to "$(realpath commit-msg)" ".git/hooks/commit-msg"
}

@test "warns if desired hook is unavailable" {
  git init

  run "./install.sh"
  assert_success
  assert_output --partial "no such file"
  assert_not_symlink_to "$(realpath commit-msg)" ".git/hooks/commit-msg"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Complex git repo behavior tests
@test "installation works if script and hooks are in subdirectory, called from subdirectory" {
  git init
  mkdir myhooks
  cp "${ROOT_DIR}/commit-msg" myhooks
  mv "install.sh" myhooks
  cd myhooks

  run "./install.sh"
  assert_success

  assert_symlink_to "$(realpath commit-msg)" "../.git/hooks/commit-msg"
}

@test "installation works if script and hooks are in subdirectory, called from root" {
  git init
  mkdir myhooks
  cp "${ROOT_DIR}/commit-msg" myhooks
  mv "install.sh" myhooks

  run "myhooks/install.sh"
  assert_success

  assert_symlink_to "$(realpath myhooks/commit-msg)" ".git/hooks/commit-msg"
}
