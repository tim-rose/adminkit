#!/bin/sh
#
# test-errno --Tests for the errno command.
#
PATH=../src:/usr/local/lib/sh:$PATH

. tap.shl
plan 5

if [ "$OS" = "darwin" ]; then
    errno_opts='-f /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/errno.h'
fi


is "$(errno $errno_opts 4)" \
    '  4: EINTR       Interrupted system call' \
    "find error by number"

is "$(errno $errno_opts EINTR)" \
    '  4: EINTR       Interrupted system call' \
    "find error by code"

is "$(errno $errno_opts 'system call')" \
    '  4: EINTR       Interrupted system call' \
    "find error by (approximate) description"

expected="\
  4: EINTR       Interrupted system call
 23: ENFILE      Too many open files in system
 30: EROFS       Read-only file system"

is "$(errno $errno_opts 'system')" "$expected" \
    "find by description can return multiple results"

expected="\
  4: EINTR       Interrupted system call
 34: ERANGE      Result too large"

is "$(errno $errno_opts 4 34)" "$expected" \
    "can find by multiple arguments"
