# git-hooks
A collection of useful git hooks!
## Usage
To install any of the hooks included herein:
1. Place the file in `.git/hooks/` for the repo to which the hook should apply.
1. Make the hook executable (`chmod +x .git/hooks/<hook_name>`).

These two steps may be accomplished using `install`:
```bash
$ install desired_hook path_to_target_repo/.git/hooks

# For example:
$ install commit-msg ~/code/my_repo/.git/hooks
```

## Installation (to another git repo)
1. Copy the desired hooks into any directory within your target git repo. I recommend making a new directory called `.git-hooks` at the root of your repo for this purpose.
1. Copy `install.sh` to the same directory that you copied the hooks to. Ensure it is executable.
1. Change directories into your git repo, and run the installation script.
  * By default, this script will attempt to install all of the hooks provided herein.
  * If desired, you can modify the configuration section of the installation script to include only specific hooks you wish to install.
  * This script will not overwrite any git hooks you already have set for your repo. If you would like to overwrite a pre-existing git hook, first manually delete the old hook and then re-run the installation script.
1. [Optional] Check both your hooks and the installation script into source control, and instruct other developers to run the installation script in their local copy of the repo.

## Development
### Writing hooks
Hooks should be written in `bash` or a `POSIX shell`, e.g., `/bin/sh`.

### Testing ![test](https://github.com/eliblock/git-hooks/workflows/test/badge.svg)

Unit testing is handled via `bats` (`brew install bats`).
Tests may also use `shellcheck` (`brew install shellcheck`).

* All tests must be in the `test` directory.
* All tests must be in a file with a `.bats` extension.
* To run all test from the root of this repo:
```bash
$ bats test
```
* All bats tests are run on every pull request to master (most recently: ![test](https://github.com/eliblock/git-hooks/workflows/test/badge.svg))
* Two helper libraries for bats are bundled via git submodules at `./test/libs/bats-assert` and `./test/libs/bats-support`. To use these libraries, you must download them:
```bash
$ git submodule update --init
```
 Then, you must load the libraries within any test file:
```bash
#!/usr/bin/env bats
load 'libs/bats-support/load' # https://github.com/ztombol/bats-support
load 'libs/bats-assert/load' # https://github.com/ztombol/bats-assert
```

## Included hooks
### `commit-msg`
Enforces [conventional commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) on your commit messages. This hook does not handle the formatting of footers (and, notably, does not enforce that footers strictly follow the commit body).
