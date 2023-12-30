#!/bin/sh

export test_a=1

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
sh "$script_dir/posix-arrays-tests.sh"
