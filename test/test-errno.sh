#!/bin/sh
#
# test-errno --Tests for the errno command.
#
MIDDEN_PATH=/usr/local/lib/sh
. midden
require tap
require test-more

plan 4

is "$(../src/errno 2)" \
    '  2: ENOENT      No such file or directory' \
    "find error by number"

is "$(../src/errno ENOENT)" \
    '  2: ENOENT      No such file or directory' \
    "find error by code"

is "$(../src/errno 'No such file')" \
    '  2: ENOENT      No such file or directory' \
    "find error by description"

expected="\
  4: EINTR       Interrupted system call
 23: ENFILE      Too many open files in system
 30: EROFS       Read-only file system"

is "$(../src/errno 'system')" "$expected" \
    "find by description can return multiple results"

expected="\
  2: ENOENT      No such file or directory
  4: EINTR       Interrupted system call"

is "$(../src/errno 2 4)" "$expected" \
    "can find by multiple arguments"

