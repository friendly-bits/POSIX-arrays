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
	___values=""; ___idex=0

	if [ -n "$*" ]; then
		for ___val in "$@"; do
			___index=$((___index+1))
			___values="${___values}${__delim1}$___index $___val"
		done
		___values="${___values#"${__delim1}"}"
	fi

	eval "emu_i_$___arr=\"$___values\""
	unset ___arr ___values ___val ___index
	return 0
}

___set_arr_el() {
	___arr="$1"; ___new_key="$2"; __new_val="$3"; __new_pairs=""

	eval "___pairs=\"\$emu_${___arr_type}_${___arr}\""
	IFS_OLD="$IFS"
	IFS="${__delim1}"
	# shellcheck disable=SC2154
	for ___pair in $___pairs; do
		___key="${___pair%% *}"
		[ "$___new_key" != "$___key" ] && __new_pairs="${__new_pairs}${__delim1}${___pair}"
	done
	IFS="$IFS_OLD"

	[ -n "$__new_val" ] && __new_pairs="${__new_pairs}${__delim1}${___new_key} ${__new_val}"
	__new_pairs="${__new_pairs#"${__delim1}"}"
	eval "emu_${___arr_type}_$___arr=\"$__new_pairs\""

	unset ___arr __new_pair __new_key ___pairs ___pair ___key __new_pairs
	return 0
}

___get_arr_el() {
	___val=""; ___arr="$1"; ___key="$2"

	eval "___pairs=\"\$emu_${___arr_type}_${___arr}\""

	IFS_OLD="$IFS"
	IFS="${__delim1}"
	# shellcheck disable=SC2154
	for ___pair in $___pairs; do
		___arr_key="${___pair%% *}"
		[ "$___arr_key" = "$___key" ] && ___val="${___pair#* }"
	done
	IFS="$IFS_OLD"

	printf '%s\n' "$___val"
	unset ___val ___arr ___key ___pairs ___pair ___arr_key

	return 0
}

# get a value from an emulated indexed array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_i_' prefix
# 1 - array name
# 2 - index
# no additional arguments are allowed
get_i_arr_el() {
	[ $# -lt 2 ] && { echo "get_i_arr_el: Error: not enough arguments." >&2; return 1; }
	[ $# -gt 2 ] && { echo "get_i_arr_el: Error: I only accept 2 arguments." >&2; return 1; }
	___arr_type="i"

	case "$2" in ''|*[!0-9]*) echo "get_i_arr_el: Error: no index specified or '$2' is not a positive integer." >&2; return 1 ;; esac
	[ "$2" -lt 1 ] && { echo "get_i_arr_el: Error: invalid index '$2'." >&2; return 1; }
	___get_arr_el "$@"
}

# get a value from an emulated associative array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_a_' prefix
# 1 - array name
# 2 - key
# no additional arguments are allowed
get_a_arr_el() {
	[ $# -lt 2 ] && { echo "get_a_arr_el: Error: not enough arguments." >&2; return 1; }
	[ $# -gt 2 ] && { echo "get_a_arr_el: Error: I only accept 2 arguments." >&2; return 1; }
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
	[ $# -lt 2 ] && { echo "set_i_arr_el: Error: not enough arguments." >&2; return 1; }
	[ $# -gt 3 ] && { echo "set_i_arr_el: Error: I only accept 2 arguments." >&2; return 1; }
	___new_index=$2; ___arr_type="i"

	case $___new_index in ''|0|*[!0-9]*) echo "get_i_arr_el: Error: no index specified or '$___new_index' is not a positive integer." >&2; return 1 ;; esac

	___set_arr_el "$@"
}

# set a key=value pair in an emulated associative array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_a_' prefix
# '#' is used as a delimiter
# 1st arg - array name
# 2nd arg - 'key=value' pair
set_a_arr_el() {
	[ $# -lt 2 ] && { echo "set_a_arr_el: Error: not enough arguments." >&2; return 1; }
	[ $# -gt 2 ] && { echo "set_a_arr_el: Error: I only accept 2 arguments." >&2; return 1; }
	__new_pair="$2"; ___arr_type="a"

	case "$__new_pair" in *=*) ;; *) echo "set_a_arr_el: Error: '$__new_pair' is not a 'key=value' pair." >&2; return 1 ;; esac
	__new_key="${__new_pair%%=*}"
	__new_val="${__new_pair#*=}"
	[ -z "$__new_key" ] && { echo "set_a_arr_el: Error: empty value provided for key in input '$__new_pair'." >&2; return 1; }

	___set_arr_el "$1" "$__new_key" "$__new_val"
}


__delim1="$(printf '\37')"