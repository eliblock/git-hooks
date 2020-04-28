# git-hooks
A collection of useful git hooks!
## Usage
To install any of the hooks included herein:
1. Place the file in `.git/hooks/` for the repo to which the hook should apply.
1. Make the hook executable (`chmod +x .git/hooks/<hook_name>`).

## Development
### Writing hooks
Hooks should be written in `bash` or a `POSIX shell`, e.g., `/bin/sh`.

### Testing
Unit testing is handled via `bats` (`brew install bats`).

* All tests must be in the `test` directory.
* All tests must be in a file with a `.bats` extension.
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
* To run all test from the root of this repo:
```bash
$ bats test
```

## Included hooks
### `commit-msg`
Enforces [conventional commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) on your commit messages. This hook does not handle the formatting of footers (and, notably, does not enforce that footers strictly follow the commit body).
