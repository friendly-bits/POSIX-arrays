#!/bin/sh

# shellcheck disable=SC2034
export arr_type="i"
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
sh "$script_dir/perf-tests.sh" "$1"
