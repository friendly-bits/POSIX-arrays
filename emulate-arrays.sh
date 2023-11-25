#!/bin/sh

# emulate-arrays.sh

# emulates arrays in a POSIX shell


# declare an emulated indexed array while populating first elements
# array contents are stored in a variable with the same name as the 'array' but with 'emu_i_' prefix
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
# array contents are stored in a variable with the same name as the 'array' but with 'emu_i_' prefix
# 1 - array name
# no additional arguments are allowed
get_i_arr_all() {
	[ $# -ne 1 ] && { echo "get_i_arr_el: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"

	eval "___pairs=\"\$emu_i_${___arr_name}\""
	# shellcheck disable=SC2154
	___pairs_sorted="$(printf '%s' "$___pairs" | tr "${___emu_arr_delim}" '\n' | sort -n)"
	___all_elements="$(
		IFS_OLD="$IFS"
		IFS="$___newline"
		for ___pair in $___pairs_sorted; do
			printf '%s' "${___pair#* } "
		done
		IFS="$IFS_OLD"
	)"

	printf '%s\n' "${___all_elements% }"
	unset ___all_elements ___arr_name ___pairs ___pair ___pairs_sorted

	return 0
}

# backend function which serves both types of arrays
___set_arr_el() {
	___arr_name="$1"; ___key="$2"; ___new_val="$3"; ___new_pairs=""

	eval "___pairs=\"\$emu_${___arr_type}_${___arr_name}\""
	___new_pairs="$(
		IFS_OLD="$IFS"
		IFS="${___emu_arr_delim}"
		# shellcheck disable=SC2154
		for ___pair in $___pairs; do
			[ "$___key" != "${___pair%% *}" ] && printf '%s' "${___emu_arr_delim}${___pair}"
		done
		IFS="$IFS_OLD"
	)"

	[ -n "$___new_val" ] && ___new_pairs="${___new_pairs}${___emu_arr_delim}${___key} ${___new_val}"
	___new_pairs="${___new_pairs#"${___emu_arr_delim}"}"

	eval "emu_${___arr_type}_$___arr_name=\"$___new_pairs\""

	unset ___arr_name ___key ___new_val ___new_pairs
	return 0
}


# backend function which serves both types of arrays
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
# array contents are stored in a variable with the same name as the 'array' but with 'emu_i_' prefix
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
# array contents are stored in a variable with the same name as the 'array' but with 'emu_a_' prefix
# 1 - array name
# 2 - key
# no additional arguments are allowed
get_a_arr_el() {
	[ $# -ne 2 ] && { echo "get_a_arr_el: Error: wrong number of arguments." >&2; return 1; }
	___arr_type="a"

	___get_arr_el "$@"
}

# set a value in an emulated indexed array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_i_' prefix
# 1 - array name
# 2 - index
# 3 - value (if no value, unsets the index)
# no additional arguments are allowed
set_i_arr_el() {
	if [ $# -lt 2 ] || [ $# -gt 3 ]; then echo "set_i_arr_el: Error: not enough arguments." >&2; return 1; fi
	___new_index=$2; ___arr_type="i"

	case $___new_index in ''|*[!0-9]*) echo "get_i_arr_el: Error: no index specified or '$___new_index' is not a nonnegative integer." >&2; return 1 ;; esac

	___set_arr_el "$@"
}

# set a key=value pair in an emulated associative array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_a_' prefix
# '#' is used as a delimiter
# 1st arg - array name
# 2nd arg - 'key=value' pair
set_a_arr_el() {
	[ $# -ne 2 ] && { echo "set_a_arr_el: Error: wrong number of arguments." >&2; return 1; }
	___new_pair="$2"; ___arr_type="a"

	case "$___new_pair" in *=*) ;; *) echo "set_a_arr_el: Error: '$___new_pair' is not a 'key=value' pair." >&2; return 1 ;; esac
	__new_key="${___new_pair%%=*}"
	___new_val="${___new_pair#*=}"
	[ -z "$__new_key" ] && { echo "set_a_arr_el: Error: empty value provided for key in input '$___new_pair'." >&2; return 1; }

	___set_arr_el "$1" "$__new_key" "$___new_val"
}


# delimiter which is used to separate pairs of values
# \37 is an ASCII escape code for 'unit separator'
# the specific escape code doesn't really matter here, as long as it's not a character
___emu_arr_delim="$(printf '\37')"
___newline="
"
