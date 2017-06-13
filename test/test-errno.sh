#!/bin/sh
#
# test-errno --Tests for the errno command.
#
MIDDEN_PATH=/usr/local/lib/sh
. midden
require tap
require test-more

plan 5

is "$(../src/errno 4)" \
    '  4: EINTR       Interrupted system call' \
    "find error by number"

is "$(../src/errno EINTR)" \
    '  4: EINTR       Interrupted system call' \
    "find error by code"

is "$(../src/errno 'system call')" \
    '  4: EINTR       Interrupted system call' \
    "find error by (approximate) description"

expected="\
  4: EINTR       Interrupted system call
 23: ENFILE      Too many open files in system
 30: EROFS       Read-only file system"

is "$(../src/errno 'system')" "$expected" \
    "find by description can return multiple results"

expected="\
  4: EINTR       Interrupted system call
 34: ERANGE      Result too large"

is "$(../src/errno 4 34)" "$expected" \
    "can find by multiple arguments"
