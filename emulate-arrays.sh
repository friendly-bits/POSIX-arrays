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
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "declare_i_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	___indices=""

	clean_i_arr "$___arr_name"
	___index=0
	if [ -n "$*" ]; then
		for ___val in "$@"; do
			eval "___emu_i_${___arr_name}_${___index}=\"$___val\""
			___indices="$___indices$___index$___emu_arr_delim"
			___index=$((___index+1))
		done
	fi

	eval "___emu_i_${___arr_name}_indices=\"$___indices\""

	unset ___val ___index ___indices
	return 0
}

clean_i_arr() {
	[ $# -ne 1 ] && { echo "clean_i_arr: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "clean_i_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___indices=\"\$___emu_i_${___arr_name}_indices\""
	___indices_sorted="$(printf '%s' "$___indices" | tr "$___emu_arr_delim" '\n' | sort -n)"

	for ___index in $___indices_sorted; do
		unset "___emu_i_${___arr_name}_${___index}"
	done
	unset "___emu_i_${___arr_name}_indices"
	unset ___indices ___indices_sorted ___index
}

# get all values from an emulated indexed array (sorted by index)
# 1 - array name
# no additional arguments are allowed
get_i_arr_all() {
	[ $# -ne 1 ] && { echo "get_i_arr_all: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"; ___all_indices=""
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_i_arr_all: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___indices=\"\$___emu_i_${___arr_name}_indices\""
	___indices_sorted="$(printf '%s' "$___indices" | tr "$___emu_arr_delim" '\n' | sort -u | sort -n)"
	for ___index in $___indices_sorted; do
		eval "___val=\"\$___emu_i_${___arr_name}_${___index}\""
		[ -n "$___val" ] && { printf '%s\n' "$___val"; ___all_indices="$___all_indices$___index$___emu_arr_delim"; }
	done
	eval "___emu_i_${___arr_name}_indices=\"$(printf '%s' "$___all_indices" | tr '\n' "$___emu_arr_delim")\""

	unset ___all_values ___indices ___indices_sorted ___index ___val ___all_indices
	return 0
}

# get all indices from an emulated indexed array (sorted)
# 1 - array name
# no additional arguments are allowed
get_i_arr_all_indices() {
	[ $# -ne 1 ] && { echo "get_i_arr_all_indices: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_i_arr_all_indices: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___indices=\"\$___emu_i_${___arr_name}_indices\""
	___indices_sorted="$(printf '%s' "$___indices" | tr "$___emu_arr_delim" '\n' | sort -u | sort -n)"
	___all_indices="$(
		for ___index in $___indices_sorted; do
			eval "___val=\"\$___emu_i_${___arr_name}_${___index}\""
			[ -n "$___val" ] && printf '%s\n' "$___index"
		done
	)"
	eval "___emu_i_${___arr_name}_indices=\"$(printf '%s' "$___all_indices" | tr '\n' "$___emu_arr_delim")\""
	printf '%s' "$___all_indices"

	unset ___indices ___indices_sorted ___index ___all_indices
	return 0
}

# set a value in an emulated indexed sparse array
# 1 - array name
# 2 - index
# 3 - value (if no value, unsets the index)
# no additional arguments are allowed
set_i_arr_el() {
	___arr_name="$1"; ___index="$2"; ___new_val="$3"
	if [ $# -lt 2 ] || [ $# -gt 3 ]; then echo "set_i_arr_el: Error: Wrong number of arguments." >&2; return 1; fi
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "set_i_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___index" in *[!0-9]*) echo "set_i_arr_el: Error: '$___index' is not a nonnegative integer." >&2; return 1 ; esac

	eval "___old_val=\"\$___emu_i_${___arr_name}_${___index}\""

	if [ -z "$___old_val" ] && [ -n "$___new_val" ]; then
		eval "___emu_i_${___arr_name}_indices=\"\${___emu_i_${___arr_name}_indices}${___index}${___emu_arr_delim}\""
	fi

	eval "___emu_i_${___arr_name}_${___index}=\"$___new_val\""

	unset ___arr_name ___index ___new_val ___indices ___old_val
	return 0
}

# get a value from an emulated indexed array
# 1 - array name
# 2 - index
# no additional arguments are allowed
get_i_arr_el() {
	if [ $# -ne 2 ]; then echo "get_i_arr_el: Error: Wrong number of arguments." >&2; return 1; fi
	___arr_name="$1"; ___index=$2
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_i_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___index" in *[!0-9]*) echo "get_i_arr_el: Error: no index specified or '$___index' is not a nonnegative integer." >&2; return 1; esac
	eval "printf '%s\n' \"\$___emu_i_${___arr_name}_${___index}\""
}




# declare an emulated associative array while populating elements
# 1 - array name
# all other args - 'key=value' pairs
declare_a_arr() {
	[ $# -lt 1 ] && { echo "declare_a_arr: Error: not enough arguments." >&2; return 1; }
	___arr_name="$1"; shift
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "declare_a_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	___keys=""

	clean_a_arr "$___arr_name"
	if [ -n "$*" ]; then
		for ___pair in "$@"; do
			case "$___pair" in *=*) ;; *) echo "declare_a_arr: Error: '$___pair' is not a 'key=value' pair." >&2; return 1 ;; esac
			___key="${___pair%%=*}"
			___val="${___pair#*=}"
			case "$___key" in *[!A-Za-z0-9_]*) echo "declare_a_arr: Error: invalid key '$___key'." >&2; return 1; esac
			eval "___emu_a_${___arr_name}_${___key}=\"$___val\""
			___keys="$___keys$___key$___emu_arr_delim"
		done
	fi

	eval "___emu_a_${___arr_name}_keys=\"$___keys\""

	unset ___val ___key ___keys
	return 0
}

# get all values from an emulated associative array (unsorted)
# 1 - array name
# no additional arguments are allowed
get_a_arr_all() {
	[ $# -ne 1 ] && { echo "get_a_arr_all: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"; ___all_keys=""
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_a_arr_all: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___keys=\"$(printf '%s' "\$___emu_a_${___arr_name}_keys")\""
	IFS_OLD="$IFS"
	IFS="$___emu_arr_delim"
	for ___key in $___keys; do
		eval "___val=\"\$___emu_a_${___arr_name}_${___key}\""
		[ -n "$___val" ] && { printf '%s\n' "$___val"; ___all_keys="$___all_keys$___key$___emu_arr_delim"; }
	done
	IFS="$IFS_OLD"
	eval "___emu_a_${___arr_name}_keys=\"$___all_keys\""

	unset ___keys ___key ___all_keys
	return 0
}

# get all keys from an emulated associative array (unsorted)
# 1 - array name
# no additional arguments are allowed
get_a_arr_all_keys() {
	[ $# -ne 1 ] && { echo "get_a_arr_all_keys: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_a_arr_all_keys: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___keys=\"\$___emu_a_${___arr_name}_keys\""
	___all_keys="$(
		IFS="$___emu_arr_delim"
		for ___key in $___keys; do
			eval "___val=\"\$___emu_a_${___arr_name}_${___key}\""
			printf '%s\n' "$___key"
		done
	)"

	eval "___emu_a_${___arr_name}_keys=\"$(printf '%s' "$___all_keys" | tr '\n' "$___emu_arr_delim")\""
	printf '%s' "$___all_keys"

	unset ___keys ___key ___all_keys
	return 0
}

# set a value in an emulated associative array
# 1 - array name
# 2 - key
# 3 - value (if no value, unsets the key)
# no additional arguments are allowed
set_a_arr_el() {
	___arr_name="$1"; ___pair="$2"
	if [ $# -ne 2 ]; then echo "set_a_arr_el: Error: Wrong number of arguments." >&2; return 1; fi
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "set_a_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___pair" in *=*) ;; *) echo "set_a_arr_el: Error: '$___pair' is not a 'key=value' pair." >&2; return 1 ;; esac
	___key="${___pair%%=*}"
	___new_val="${___pair#*=}"
	case "$___key" in *[!A-Za-z0-9_]*) echo "set_a_arr_el: Error: invalid key '$___key'." >&2; return 1; esac

	eval "___old_val=\"\$___emu_a_${___arr_name}_${___key}\""

	if [ -z "$___old_val" ] && [ -n "$___new_val" ]; then
		eval "___emu_a_${___arr_name}_keys=\"\${___emu_a_${___arr_name}_keys}${___key}${___emu_arr_delim}\""
	fi

	eval "___emu_a_${___arr_name}_${___key}=\"$___new_val\""

	unset ___arr_name ___key ___new_val ___keys ___old_val
	return 0
}

# get a value from an emulated associative array
# 1 - array name
# 2 - key
# no additional arguments are allowed
get_a_arr_el() {
	if [ $# -ne 2 ]; then echo "get_a_arr_el: Error: Wrong number of arguments." >&2; return 1; fi
	___arr_name="$1"; ___key=$2
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_a_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___key" in *[!A-Za-z0-9_]*) echo "get_a_arr_el: Error: invalid key '$___key'." >&2; return 1; esac

	eval "printf '%s\n' \"\$___emu_a_${___arr_name}_${___key}\""
}

clean_a_arr() {
	[ $# -ne 1 ] && { echo "clean_a_arr: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "clean_a_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	eval "___keys=\"\$___emu_a_${___arr_name}_keys\""

	IFS_OLD="$IFS"
	IFS="$___emu_arr_delim"
	for ___key in $___keys; do
		unset "___emu_a_${___arr_name}_${___key}"
	done
	IFS="$IFS_OLD"
	unset "___emu_a_${___arr_name}_keys"
	unset ___keys ___key
}



___newline="
"

# delimiter which is used to separate pairs of values
# \35 is an ASCII escape code for 'group separator'
# \37 is an ASCII escape code for 'unit separator'
# the specific escape codes shouldn't really matter here, as long as it's not a character

___emu_arr_delim="$(printf '\35')"