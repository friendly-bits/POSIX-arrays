#!/bin/sh

# emulate-arrays.sh

# emulates arrays in a POSIX shell


# declare an emulated indexed array while populating first elements
# array contents are stored in a variable with the same name as the 'array' but with 'emu_i_' prefix
# 1 - array name
# all other args - array values
declare_i_arr() {
	[ $# -lt 1 ] && { echo "declare_i_arr: Error: not enough arguments." >&2; return 1; }
	arr="$1"; shift
	if [ -n "$*" ]; then
		for val in "$@"; do
			values="${values}#$val"
		done
		values="${values#\#}"
		eval "emu_i_$arr=\"$values\""
	fi

	unset arr values val
	return 0
}

# Probably not needed
# # declare an asociative array
# # 1 - array name
# # no additional arguments allowed
# declare_A_arr() {
# 	[ $# -lt 1 ] && { echo "declare_A: Error: not enough arguments." >&2; return 1; }
# 	arr="$1"; shift
# 	[ -n "$*" ] && { echo "declare_A: Error: I only accept one argument." >&2; return 1; }
# 	eval "$arr="
# 	assoc_arrays="${arr} ${assoc_arrays}"
# 	assoc_arrays="${assoc_arrays#\ }"
# 	unset arr
# 	return 0
# }

# get a value from an emulated indexed array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_i_' prefix
# 1 - array name
# 2 - index
# no additional arguments are allowed
get_i_arr_el() {
	[ $# -lt 2 ] && { echo "get_i_arr_el: Error: not enough arguments." >&2; return 1; }
	res=""; arr="$1"; index="$2"; shift 2
	[ -n "$*" ] && { echo "get_i_arr_el: Error: I only accept 2 arguments." >&2; return 1; }
	case "$index" in ''|*[!0-9]*) echo "get_i_arr_el: Error: no index specified or '$index' is not a positive integer." >&2; return 1 ;; esac
	[ "$index" -lt 1 ] && { echo "get_i_arr_el: Error: invalid index '$index'." >&2; return 1; }

	eval "values=\"\$emu_i_$arr\""

	i=0
	IFS_OLD="$IFS"
	IFS='#'
	for val in $values; do
		i=$((i+1))
		[ $i -eq "$index" ] && { res="$val"; break; }
	done
	IFS="$IFS_OLD"

	printf '%s\n' "$res"
	unset arr values val res index i

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
	arr="$1"; index="$2"; new_val="$3"; shift 3
	[ -n "$*" ] && { echo "set_i_arr_el: Error: I only accept 2 arguments." >&2; return 1; }
	case "$index" in ''|*[!0-9]*) echo "set_i_arr_el: Error: no index specified or '$index' is not a positive integer." >&2; return 1 ;; esac
	[ "$index" -lt 1 ] && { echo "set_i_arr_el: Error: invalid index '$index'." >&2; return 1; }

	eval "values=\"\$emu_i_$arr\""
	i=0
	IFS_OLD="$IFS"
	IFS='#'
	for val in $values; do
		i=$((i+1))
		[ $i -eq "$index" ] && val="$new_val"
		new_values="${new_values}#$val"
	done
	IFS="$IFS_OLD"

	if [ $i -lt "$index" ]; then
		# shellcheck disable=SC2034
		for j in $(seq $i $((index-2)) ); do
			new_values="${new_values}#"
		done
		new_values="${new_values}#${new_val}"
	fi
	new_values="${new_values#\#}"

	eval "emu_i_$arr=\"$new_values\""

	unset arr values new_values val index i j

	return 0
}

# set a key=value pair in an emulated associative array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_a_' prefix
# '#' is used as a delimiter
# 1st arg - array name
# 2nd arg - 'key=value' pair
set_a_arr_el() {
	[ $# -lt 2 ] && { echo "set_a_arr_el: Error: not enough arguments." >&2; return 1; }
	arr="$1"; new_pair="$2"; shift 2
	[ -n "$*" ] && { echo "set_a_arr_el: Error: I only accept 2 arguments." >&2; return 1; }
	case "$new_pair" in *=*) ;; *) echo "set_a_arr_el: Error: '$new_pair' is not a 'key=value' pair." >&2; return 1 ;; esac
	new_key="${new_pair%%=*}"
	[ -z "$new_key" ] && { echo "set_a_arr_el: Error: empty value provided for key in input '$new_pair'." >&2; return 1; }
	new_val="${new_pair##*=}"
	eval "pairs=\"\$emu_a_$arr\""

	IFS_OLD="$IFS"
	IFS='#'
	# shellcheck disable=SC2154
	for pair in $pairs; do
		key="${pair%%=*}"
		[ "$new_key" != "$key" ] && new_pairs="${new_pairs}#$pair"
	done
	IFS="$IFS_OLD"

	[ -n "$new_val" ] && new_pairs="${new_pairs}#$new_pair"
	new_pairs="${new_pairs#\#}"

	eval "emu_a_$arr=\"$new_pairs\""

	unset arr new_pair new_key pairs pair key new_pairs
	return 0
}

# get a value from an emulated associative array
# array contents are stored in a variable with the same name as the 'array' but with 'emu_a_' prefix
# 1 - array name
# 2 - key
# no additional arguments are allowed
get_a_arr_el() {
	[ $# -lt 2 ] && { echo "get_a_arr_el: Error: not enough arguments." >&2; return 1; }
	res=""; arr="$1"; key="$2"; shift 2
	[ -n "$*" ] && { echo "get_a_arr_el: Error: I only accept 2 arguments." >&2; return 1; }

	eval "pairs=\"\$emu_a_$arr\""

	IFS_OLD="$IFS"
	IFS='#'
	for pair in $pairs; do
		arr_key="${pair%%=*}"
		[ "$arr_key" = "$key" ] && res="${pair##*=}"
	done
	IFS="$IFS_OLD"

	printf '%s\n' "$res"
	unset res arr key pairs pair arr_key

	return 0
}

# set_a_arr_el test1 "a=b"
# set_a_arr_el test1 "aa=bb"
# set_a_arr_el test1 "aaa=c"
# set_a_arr_el test1 "aa=e"
# set_a_arr_el test1 "a="
# 
# get_a_arr_el test1 aa
# 
# set_i_arr_el testN 3 "aa"
# get_i_arr_el testN 1
# get_i_arr_el testN 2
# get_i_arr_el testN 3
# 
# #shellcheck disable=SC2154
# echo "testN: '$testN'"
