#!/bin/sh

# emulate-arrays.sh

# emulates arrays in a POSIX shell


# declare an emulated indexed array while populating first elements
# array contents are stored in a variable with the same name as the 'array' but with 'emu_i_' prefix
# 1 - array name
# all other args - array values
declare_i_arr() {
	[ $# -lt 1 ] && { echo "declare_i_arr: Error: not enough arguments." >&2; return 1; }
	___arr="$1"; shift
	if [ -n "$*" ]; then
		for ___val in "$@"; do
			___values="${___values}#$___val"
		done
		___values="${___values#\#}"
		eval "emu_i_$___arr=\"$___values\""
	fi

	unset ___arr ___values ___val
	return 0
}

# get a value from an emulated indexed array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_i_' prefix
# 1 - array name
# 2 - index
# no additional arguments are allowed
get_i_arr_el() {
	[ $# -lt 2 ] && { echo "get_i_arr_el: Error: not enough arguments." >&2; return 1; }
	___res=""; ___arr="$1"; ___index="$2"; shift 2
	[ -n "$*" ] && { echo "get_i_arr_el: Error: I only accept 2 arguments." >&2; return 1; }
	case "$___index" in ''|*[!0-9]*) echo "get_i_arr_el: Error: no index specified or '$___index' is not a positive integer." >&2; return 1 ;; esac
	[ "$___index" -lt 1 ] && { echo "get_i_arr_el: Error: invalid index '$___index'." >&2; return 1; }

	eval "___values=\"\$emu_i_$___arr\""

	___i=0
	IFS_OLD="$IFS"
	IFS='#'
	for ___val in $___values; do
		___i=$((___i+1))
		[ $___i -eq "$___index" ] && { ___res="$___val"; break; }
	done
	IFS="$IFS_OLD"

	printf '%s\n' "$___res"
	unset ___arr ___values ___val ___res ___index ___i

	return 0
}

# set a value in an emulated indexed array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_i_' prefix
# 1 - array name
# 2 - index
# 3 - value
# no additional arguments are allowed
set_i_arr_el() {
	[ $# -lt 3 ] && { echo "set_i_arr_el: Error: not enough arguments." >&2; return 1; }
	___arr="$1"; ___index="$2"; __new_val="$3"; shift 3
	[ -n "$*" ] && { echo "set_i_arr_el: Error: I only accept 3 arguments." >&2; return 1; }
	case "$___index" in ''|*[!0-9]*) echo "set_i_arr_el: Error: no index specified or '$___index' is not a positive integer." >&2; return 1 ;; esac
	[ "$___index" -lt 1 ] && { echo "set_i_arr_el: Error: invalid index '$___index'." >&2; return 1; }

	eval "___values=\"\$emu_i_$___arr\""
	__i=0
	IFS_OLD="$IFS"
	IFS='#'
	for ___val in $___values; do
		__i=$((__i+1))
		[ $__i -eq "$___index" ] && ___val="$__new_val"
		__new_values="${__new_values}#$___val"
	done
	IFS="$IFS_OLD"

	if [ $__i -lt "$___index" ]; then
		# shellcheck disable=SC2034
		for __j in $(seq $__i $((___index-2)) ); do
			__new_values="${__new_values}#"
		done
		__new_values="${__new_values}#${__new_val}"
	fi
	__new_values="${__new_values#\#}"

	eval "emu_i_$___arr=\"$__new_values\""

	unset ___arr ___values __new_values ___val ___index __i __j

	return 0
}

# set a key=value pair in an emulated associative array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_a_' prefix
# '#' is used as a delimiter
# 1st arg - array name
# 2nd arg - 'key=value' pair
set_a_arr_el() {
	[ $# -lt 2 ] && { echo "set_a_arr_el: Error: not enough arguments." >&2; return 1; }
	___arr="$1"; __new_pair="$2"; shift 2
	[ -n "$*" ] && { echo "set_a_arr_el: Error: I only accept 2 arguments." >&2; return 1; }
	case "$__new_pair" in *=*) ;; *) echo "set_a_arr_el: Error: '$__new_pair' is not a 'key=value' pair." >&2; return 1 ;; esac
	__new_key="${__new_pair%%=*}"
	[ -z "$__new_key" ] && { echo "set_a_arr_el: Error: empty value provided for key in input '$__new_pair'." >&2; return 1; }
	__new_val="${__new_pair##*=}"
	eval "___pairs=\"\$emu_a_$___arr\""

	IFS_OLD="$IFS"
	IFS='#'
	# shellcheck disable=SC2154
	for ___pair in $___pairs; do
		___key="${___pair%%=*}"
		[ "$__new_key" != "$___key" ] && __new_pairs="${__new_pairs}#$___pair"
	done
	IFS="$IFS_OLD"

	[ -n "$__new_val" ] && __new_pairs="${__new_pairs}#$__new_pair"
	__new_pairs="${__new_pairs#\#}"

	eval "emu_a_$___arr=\"$__new_pairs\""

	unset ___arr __new_pair __new_key ___pairs ___pair ___key __new_pairs
	return 0
}

# get a value from an emulated associative array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_a_' prefix
# 1 - array name
# 2 - key
# no additional arguments are allowed
get_a_arr_el() {
	[ $# -lt 2 ] && { echo "get_a_arr_el: Error: not enough arguments." >&2; return 1; }
	___res=""; ___arr="$1"; ___key="$2"; shift 2
	[ -n "$*" ] && { echo "get_a_arr_el: Error: I only accept 2 arguments." >&2; return 1; }

	eval "___pairs=\"\$emu_a_$___arr\""

	IFS_OLD="$IFS"
	IFS='#'
	for ___pair in $___pairs; do
		___arr_key="${___pair%%=*}"
		[ "$___arr_key" = "$___key" ] && ___res="${___pair##*=}"
	done
	IFS="$IFS_OLD"

	printf '%s\n' "$___res"
	unset ___res ___arr ___key ___pairs ___pair ___arr_key

	return 0
}
