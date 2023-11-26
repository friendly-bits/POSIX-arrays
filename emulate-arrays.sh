#!/bin/sh

# emulate-arrays.sh

# emulates arrays in a POSIX shell

# array contents are stored in a variable with the same name as the 'array' but with 'emu_[x]_' prefix
# where [x] is either 'a' for associative array or [i] for indexed array


# declare an emulated indexed array while populating first elements
# 1 - array name
# all other args - array values
declare_i_arr() {
	[ $# -lt 1 ] && { echo "declare_i_arr: Error: not enough arguments." >&2; return 1; }
	___arr_name="$1"; shift
	___values=""; ___index=0

	if [ -n "$*" ]; then
		for ___val in "$@"; do
			___values="${___values}${___emu_arr_delim}$___index $___val"
			___index=$((___index+1))
		done
		___values="${___values#"${___emu_arr_delim}"}"
	fi

	eval "emu_i_$___arr_name=\"$___values\""
	unset ___arr_name ___values ___val ___index
	return 0
}

# get all values from an emulated indexed array (sorted by index)
# 1 - array name
# no additional arguments are allowed
get_i_arr_all() {
	[ $# -ne 1 ] && { echo "get_i_arr_all: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"

	eval "___pairs=\"\$emu_i_${___arr_name}\""
	# shellcheck disable=SC2154
	___pairs_sorted="$(printf '%s' "$___pairs" | tr "${___emu_arr_delim}" '\n' | sort -n)"
	___all_values="$(
		IFS_OLD="$IFS"
		IFS="$___newline"
		for ___pair in $___pairs_sorted; do
			printf '%s' "${___pair#* } "
		done
		IFS="$IFS_OLD"
	)"

	printf '%s\n' "${___all_values% }"
	unset ___all_values ___arr_name ___pairs_sorted

	return 0
}

# get all keys from an emulated associative array (unsorted)
# 1 - array name
# no additional arguments are allowed
get_a_arr_all_keys() {
	[ $# -ne 1 ] && { echo "get_a_arr_all_keys: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	eval "___pairs=\"\$emu_a_${___arr_name}\""
	# shellcheck disable=SC2154
	___all_keys="$(
		IFS_OLD="$IFS"
		IFS="${___emu_arr_delim}"
		for ___pair in $___pairs; do
			printf '%s' "${___pair%% *} "
		done
		IFS="$IFS_OLD"
	)"

	printf '%s\n' "${___all_keys% }"
	unset ___all_keys ___arr_name

	return 0
}


# set a value in an emulated indexed array
# 1 - array name
# 2 - index
# 3 - value (if no value, unsets the index)
# no additional arguments are allowed
set_i_arr_el() {
	if [ $# -lt 2 ] || [ $# -gt 3 ]; then echo "set_i_arr_el: Error: Wrong number of arguments." >&2; return 1; fi
	___arr_name="$1"; ___arr_index=$2; ___new_val="$3"

	case $___arr_index in ''|*[!0-9]*) echo "get_i_arr_el: Error: no index specified or '$___arr_index' is not a nonnegative integer." >&2; return 1 ;; esac

	eval "___pairs=\"\$emu_i_${___arr_name}\""
	___new_pairs="$(
		IFS_OLD="$IFS"
		IFS="${___emu_arr_delim}"
		# shellcheck disable=SC2154
		for ___pair in $___pairs; do
			[ "$___arr_index" != "${___pair%% *}" ] && printf '%s' "${___emu_arr_delim}${___pair}"
		done
		IFS="$IFS_OLD"
	)"

	[ -n "$___new_val" ] && ___new_pairs="${___new_pairs}${___emu_arr_delim}${___arr_index} ${___new_val}"
	___new_pairs="${___new_pairs#"${___emu_arr_delim}"}"

	eval "emu_i_$___arr_name=\"$___new_pairs\""

	unset ___arr_name ___new_val ___new_pairs ___arr_index ___pairs
	return 0
}

# set a key=value pair in an emulated associative array
# 1st arg - array name
# 2nd arg - 'key=value' pair
# no additional arguments are allowed
set_a_arr_el() {
	[ $# -ne 2 ] && { echo "set_a_arr_el: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"; ___new_pair="$2"

	case "$___new_pair" in *=*) ;; *) echo "set_a_arr_el: Error: '$___new_pair' is not a 'key=value' pair." >&2; return 1 ;; esac
	___new_key="${___new_pair%%=*}"
	___new_val="${___new_pair#*=}"

	[ -z "$___new_key" ] && { echo "set_a_arr_el: Error: empty value provided for key in input '$___new_pair'." >&2; return 1; }

	eval "___pairs=\"\$emu_a_${___arr_name}\""
	___new_pairs="$(
		IFS_OLD="$IFS"
		IFS="${___emu_arr_delim}"
		# shellcheck disable=SC2154
		for ___pair in $___pairs; do
			[ "$___new_key" != "${___pair%% *}" ] && printf '%s' "${___emu_arr_delim}${___pair}"
		done
		IFS="$IFS_OLD"
	)"

	___new_pairs="${___new_pairs}${___emu_arr_delim}${___new_key} ${___new_val}"
	___new_pairs="${___new_pairs#"${___emu_arr_delim}"}"

	eval "emu_a_$___arr_name=\"$___new_pairs\""

	unset ___arr_name ___new_pair ___new_key ___new_val ___new_pairs
	return 0
}


# backend function which serves both types of arrays
# 1 - array name
# 2 - key/index
___get_arr_el() {
	___val=""; ___arr_name="$1"; ___key="$2"

	eval "___pairs=\"\$emu_${___arr_type}_${___arr_name}\""

	IFS_OLD="$IFS"
	IFS="${___emu_arr_delim}"
	# shellcheck disable=SC2154
	for ___pair in $___pairs; do
		___arr_key="${___pair%% *}"
		[ "$___arr_key" = "$___key" ] && { ___val="${___pair#* }"; break; }
	done
	IFS="$IFS_OLD"

	printf '%s\n' "$___val"
	unset ___val ___arr_name ___key ___pairs ___pair ___arr_key

	return 0
}

# get a value from an emulated indexed array
# 1 - array name
# 2 - index
# no additional arguments are allowed
get_i_arr_el() {
	[ $# -ne 2 ] && { echo "get_i_arr_el: Error: wrong number of arguments." >&2; return 1; }
	___arr_type="i"

	case "$2" in ''|*[!0-9]*) echo "get_i_arr_el: Error: no index specified or '$2' is not a nonnegative integer." >&2; return 1 ;; esac
	___get_arr_el "$@"
}

# get a value from an emulated associative array
# 1 - array name
# 2 - key
# no additional arguments are allowed
get_a_arr_el() {
	[ $# -ne 2 ] && { echo "get_a_arr_el: Error: wrong number of arguments." >&2; return 1; }
	___arr_type="a"

	___get_arr_el "$@"
}


___newline="
"

# delimiter which is used to separate pairs of values
# \37 is an ASCII escape code for 'unit separator'
# the specific escape code doesn't really matter here, as long as it's not a character
___emu_arr_delim="$(printf '\37')"
