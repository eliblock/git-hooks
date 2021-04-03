#!/usr/bin/env bats
load 'libs/bats-support/load' # https://github.com/ztombol/bats-support
load 'libs/bats-assert/load' # https://github.com/ztombol/bats-assert

SUCCESS_MESSAGE_SNIPPET=" commit message follows conventional commits syntax"
FIXUP_MESSAGE="Conventional commit message check skipped on fixup commits."

setup() {
    if [ "${BATS_TEST_NUMBER}" = 1 ];then
        echo "# ----- $(basename "${BATS_TEST_FILENAME}") ----- " >&3
    fi
}

@test "commit-msg.bats file passes shellcheck" {
  if [ "${RUNNING_IN_CI}" -eq 1 ]; then
    skip "shellcheck on ubuntu cannot handle a bats file, so we skip it by setting RUNNING_IN_CI to 1"
  fi
  run which shellcheck # `brew install shellcheck` if this test fails
  refute_output ""

  run shellcheck "${BATS_TEST_FILENAME}"
  assert_success
}

@test "commit-msg file passes shellcheck" {
  run which shellcheck # `brew install shellcheck` if this test fails
  refute_output ""

  run shellcheck commit-msg
  assert_success
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Simple cases (success):
@test "passes compliant one-liner" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes compliant one-liner with scope" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat(location): a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes compliant one-liner with bang" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat!: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes compliant one-liner with scope and bang" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat(asdf)!: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Simple cases (fails):
@test "fails if not passed a valid file" {
  run ./commit-msg

  assert_failure
  assert_output --partial "No such file"
}

@test "fails noncompliant one-liner" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "a non-compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails one-liner with empty scope" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat():a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails one-liner with no type" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "(asdf):a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails one-liner with no type but with scope" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "(asdf):a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails one-liner with no type but with bang" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "!:a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails one-liner with no type but with scope and bang" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "(asdf)!:a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails one-liner with multi-word type" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "more words:a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails one-liner with multi-word scope" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat(neat spot):a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails one-liner with no space after colon" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat:a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails one-liner with extra space after colon" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat:  a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails zero-liner" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

@test "fails blank multi-liner" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "\n\nUseless line here.\n\n\n" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Simple cases (skips):
@test "ignores single-line merge commits" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "Merge pull request #123" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 0
  assert_success
  assert_output --partial "skipped on merge commits"
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "catches failures after first line in merge commits" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "Merge pull request #123\nbad second line" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "skipped on merge commits"
  assert_output --partial  "must be blank"
}

@test "ignores single-line revert commits (titlecase)" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "Revert a broken thing" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 0
  assert_success
  assert_output --partial "skipped on revert commits"
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "ignores single-line revert commits (lowercase)" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "revert a broken thing" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 0
  assert_success
  assert_output --partial "skipped on revert commits"
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "catches failures after first line in merge commits" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "Revert a broken thing\nbad second line" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "skipped on revert commits"
  assert_output --partial  "must be blank"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Passes all valid types:
# build, chore, ci, docs, feat, fix, perf, refactor, style, test, wip

@test "passes one-lines with type build" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "build: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes one-lines with type chore" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "chore: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes one-lines with type ci" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "ci: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes one-lines with type docs" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "docs: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes one-lines with type feat" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes one-lines with type fix" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "fix: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes one-lines with type perf" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "perf: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes one-lines with type refactor" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "refactor: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes one-lines with type style" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "style: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes one-lines with type test" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "test: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "passes one-lines with type wip" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "wip: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# First line length

@test "passes compliant one-liner with 50 characters" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat: 78901234567890123456789012345678901234567890" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "fails compliant one-liner with 51 characters" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "feat: 789012345678901234567890123456789012345678901" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "50 characters"
}

@test "fails non-compliant one-liner with 51 characters with 2 errors" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo "123456789012345678901234567890123456789012345678901" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 2
  assert_failure
  assert_output --partial "conventional commit messages"
  assert_output --partial "50 characters"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Multiple lines
@test "passes compliant multi-liner" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "feat(asdf)!: a compliant multi-liner\n\nthis is a valid body\nfor the commit" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "fails if second line isn't blank" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "feat(asdf)!: a compliant multi-liner\ninvalid stuff\n\nthis is a valid body for the commit" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "must be blank"
}

@test "fails and warns non-compliant multi-liner with 73 character 3rd line" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "a non-compliant multi-liner\n\n1234567890123456789012345678901234567890123456789012345678901234567890123" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_equal "${status}" 1
  assert_failure
  assert_output --partial "conventional commit messages"
  assert_output --partial "72 characters"
  assert_output --partial "Line #3 has"
}

@test "warns compliant multi-liner with 73 character 3rd line" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "feat(asdf)!: a compliant multi-liner\n\n1234567890123456789012345678901234567890123456789012345678901234567890123" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "72 characters"
  assert_output --partial "Line #3 has"
}

@test "warns compliant multi-liner with 73 character 4th line" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "feat(asdf)!: a compliant multi-liner\n\nValid line\n1234567890123456789012345678901234567890123456789012345678901234567890123\nValid line" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "72 characters"
  assert_output --partial "Line #4 has"
}

@test "warns compliant multi-liner with multiple too-long body lines" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "feat(asdf)!: a compliant multi-liner\n\n1234567890123456789012345678901234567890123456789012345678901234567890123\n1234567890123456789012345678901234567890123456789012345678901234567890123" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "72 characters"
  assert_output --partial "Line #3 has"
  assert_output --partial "Line #4 has"
}

@test "does not warn compliant multi-liner with 74 character comment in 4th line" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "feat(asdf)!: a compliant multi-liner\n\nValid line\n#1234567890123456789012345678901234567890123456789012345678901234567890123\nValid line" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  refute_output --partial "72 characters"
}

@test "passes compliant multi-liner with 72 character 3rd line" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "feat(asdf)!: a compliant multi-liner\n\n123456789012345678901234567890123456789012345678901234567890123456789012" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Comments:
@test "skips first line comment" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "#\nfeat(asdf)!: a compliant one-liner" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "skips second line comment" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "feat(asdf)!: a compliant multi-liner\n#valid comment\n\nthis is a valid body for the commit" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Fixup commits:
@test "skips fixup commits (conventional format)" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "fixup! feat: an old commit message" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${FIXUP_MESSAGE}"
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "skips fixup commits (long first line)" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "fixup! 01234567890123456789012345678901234567890123456789" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${FIXUP_MESSAGE}"
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "skips fixup commits (empty second line)" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "fixup! feat: an old commit message\nNot empty!\n" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${FIXUP_MESSAGE}"
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}

@test "skips fixup commits (long body lines)" {
  FILE="${BATS_TMPDIR}/${BATS_TEST_NUMBER}"
  echo -e "fixup! feat: an old commit message\n\nValid line\n1234567890123456789012345678901234567890123456789012345678901234567890123\nValid line" > "${FILE}"

  run ./commit-msg "${FILE}"

  assert_success
  assert_output --partial "${FIXUP_MESSAGE}"
  refute_output --partial "72"
  assert_output --partial "${SUCCESS_MESSAGE_SNIPPET}"
}
