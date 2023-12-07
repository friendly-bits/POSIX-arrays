#!/bin/sh

# emulate-arrays.sh

# emulates arrays in POSIX shell

# each array element is stored in a variable named in the format '___emu_[x]_[arr_name]_[key/index]'
# where [x] is either 'a' for associative array or 'i' for indexed array

# keys/indices are stored in a variable named in the format '___emu_[x]_[arr_name]_keys' or '___emu_[x]_[arr_name]_indices'

# declare an emulated indexed array while populating first elements
# 1 - array name
# all other args - array values
declare_i_arr() {
	[ $# -lt 1 ] && { echo "declare_i_arr: Error: '$*': $# - not enough arguments." >&2; return 1; }
	___arr_name="$1"; shift
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "declare_i_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___indices=\"\$___emu_i_${___arr_name}_indices\""

	for ___index in $___indices; do
		unset "___emu_i_${___arr_name}_${___index}"
	done
	unset "___emu_i_${___arr_name}_indices"
	unset ___indices "___emu_i_${___arr_name}_high_index"

	___index=0
	if [ -n "$*" ]; then
		for ___val in "$@"; do
			eval "___emu_i_${___arr_name}_${___index}=\"$___val\""
			___indices="$___indices$___index$___newline"
			___index=$((___index + 1))
		done
	fi

	eval "___emu_i_${___arr_name}_high_index=\"$((___index - 1))\""
	eval "___emu_i_${___arr_name}_indices=\"$___indices\""
	eval "___emu_i_${___arr_name}_sorted=1"

	unset ___val ___index ___indices
	return 0
}

# read lines from input string or from a file into an indexed array
# array is reset if already exists
# 1 - array name
# 2 - newline-separated string
# no additional arguments are allowed
read_i_arr() {
	[ $# -ne 2 ] && { echo "read_i_arr: Error: '$*': $# - wrong number of arguments." >&2; return 1; }
	___arr_name="$1"; ___lines="$2"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "read_i_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___indices=\"\$___emu_i_${___arr_name}_indices\""

	for ___index in $___indices; do
		unset "___emu_i_${___arr_name}_${___index}"
	done
	unset "___emu_i_${___arr_name}_indices"
	unset ___indices "___emu_i_${___arr_name}_high_index"

	___index=0
    IFS_OLD="$IFS"
    IFS="$___newline"
	for ___line in $___lines; do
		eval "___emu_i_${___arr_name}_${___index}=\"$___line\""
		___indices="$___indices$___index$___newline"
		___index=$((___index + 1))
	done
    IFS="$IFS_OLD"

	eval "___emu_i_${___arr_name}_high_index=\"$((___index - 1))\""
	eval "___emu_i_${___arr_name}_indices=\"$___indices\""
	eval "___emu_i_${___arr_name}_sorted=1"

	unset ___line ___lines ___index ___indices ___input_file
	return 0
}

clean_i_arr() {
	[ $# -ne 1 ] && { echo "clean_i_arr: Error: '$*': $# - wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "clean_i_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___indices=\"\$___emu_i_${___arr_name}_indices\""

	for ___index in $___indices; do
		unset "___emu_i_${___arr_name}_${___index}"
	done
	unset "___emu_i_${___arr_name}_indices"
	unset ___indices ___index "___emu_i_${___arr_name}_high_index" "___emu_i_${___arr_name}_sorted"
}

# get all values from an emulated indexed array (sorted by index)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_values() {
	[ $# -ne 2 ] && { echo "get_i_arr_all: Error: '$*': $# - wrong number of arguments." >&2; return 1; }
	___arr_name="$1"; ___out_var="$2"; ___values=''
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_i_arr_all: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___sorted=\"\$___emu_i_${___arr_name}_sorted\""
	if [ -z "$___sorted" ]; then
		___indices="$(eval "printf '%s\n' \"\$___emu_i_${___arr_name}_indices\"" | sort -nu)$___newline"
		eval "___emu_i_${___arr_name}_indices=\"$___indices$___newline\""
		eval "___emu_i_${___arr_name}_sorted=1"
	else
		eval "___indices=\"\$___emu_i_${___arr_name}_indices\""
	fi

	[ -n "$___indices" ] && ___values="$(
	for ___index in $___indices; do
		eval "___val=\"\$___emu_i_${___arr_name}_${___index}\""
		[ -n "$___val" ] && printf '%s ' "$___val"
	done
	)"

	eval "$___out_var=\"${___values% }\""

	unset ___values ___indices ___index ___val ___sorted ___out_var
	return 0
}

# get all indices from an emulated indexed array (sorted)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_indices() {
	[ $# -ne 2 ] && { echo "get_i_arr_all_indices: Error: '$*': $# - wrong number of arguments." >&2; return 1; }
	___arr_name="$1" ___out_var_name="$2"; ___res_indices=''
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_i_arr_all_indices: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___sorted=\"\$___emu_i_${___arr_name}_sorted\""
	if [ -z "$___sorted" ]; then
		___indices="$(eval "printf '%s\n' \"\$___emu_i_${___arr_name}_indices\"" | sort -nu)$___newline"
		eval "___emu_i_${___arr_name}_indices=\"$___indices\""
		eval "___emu_i_${___arr_name}_sorted=1"
	else
		eval "___indices=\"\$___emu_i_${___arr_name}_indices\""
	fi

	___res_indices="$(
		for ___index in $___indices; do
			eval "___val=\"\$___emu_i_${___arr_name}_${___index}\""
			[ -n "$___val" ] &&
			printf '%s ' "$___index"
		done
	)"

	eval "$___out_var_name=\"${___res_indices% }\""

	unset ___indices ___res_indices ___index ___sorted ___out_var_name ___val
	return 0
}

# add a new element to an indexed array and set its value
# 1 - array name
# 2 - value
# no additional arguments are allowed
add_i_arr_el() {
	___arr_name="$1"; ___new_val="$2"
	if [ $# -ne 2 ]; then echo "add_i_arr_el: Error: '$*': $# - wrong number of arguments." >&2; return 1; fi
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "add_i_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___high_index=\"\$___emu_i_${___arr_name}_high_index\""

	if [ -z "$___high_index" ]; then
		if eval [ -z "\$___emu_i_${___arr_name}_sorted" ]; then
			eval "___indices=\"\$___emu_i_${___arr_name}_indices\""
			[ -n "$___indices" ] && {
				___indices="$(
				for ___index in $___indices; do
					eval "___val=\"\$___emu_i_${___arr_name}_${___index}\""
					if [ -n "$___val" ]; then
						printf '%s\n' "$___index"
					fi
				done | sort -nu
				)$___newline"
			}
			eval "___emu_i_${___arr_name}_sorted=1"
		else
			eval "___indices=\"\$___emu_i_${___arr_name}_indices\""
		fi

		[ -n "$___indices" ] && {
			___high_index="${___indices%"$___newline"}"
			___high_index="${___high_index##*"$___newline"}"
		} || ___high_index="-1"

		___index=$((___high_index + 1))
		eval "___emu_i_${___arr_name}_indices=\"${___indices}${___index}${___newline}\""
	else
		___index=$((___high_index + 1))
		eval "___emu_i_${___arr_name}_indices=\"\${___emu_i_${___arr_name}_indices}${___index}${___newline}\""
	fi

	eval "___emu_i_${___arr_name}_high_index=\"$___index\""
	eval "___emu_i_${___arr_name}_${___index}=\"$___new_val\""

	unset ___new_val ___val ___indices ___index ___high_index
	return 0
}

# set a value in an emulated indexed sparse array
# 1 - array name
# 2 - index
# 3 - value (if no value, unsets the index)
# no additional arguments are allowed
set_i_arr_el() {
	___arr_name="$1"; ___index="$2"; ___new_val="$3"
	if [ $# -lt 2 ] || [ $# -gt 3 ]; then echo "set_i_arr_el: Error: '$*': $# - wrong number of arguments." >&2; return 1; fi
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "set_i_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___index" in *[!0-9]*) echo "set_i_arr_el: Error: '$___index' is not a nonnegative integer." >&2; return 1 ; esac

	eval "___old_val=\"\$___emu_i_${___arr_name}_${___index}\""

	if [ -z "$___old_val" ] && [ -n "$___new_val" ]; then
		eval "___emu_i_${___arr_name}_indices=\"\${___emu_i_${___arr_name}_indices}${___index}${___newline}\""
	fi

	eval "___emu_i_${___arr_name}_${___index}=\"$___new_val\""

	unset ___index ___new_val ___old_val "___emu_i_${___arr_name}_high_index" "___emu_i_${___arr_name}_sorted"
	return 0
}

# get a value from an emulated indexed array
# output is set as a value of a global variable
# 1 - array name
# 2 - index
# 3 - global variable name for output
# no additional arguments are allowed
get_i_arr_el() {
	if [ $# -ne 3 ]; then echo "get_i_arr_el: Error: '$*': $# - wrong number of arguments." >&2; return 1; fi
	___arr_name="$1"; ___index="$2"; ___out_var_name="$3"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_i_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___index" in *[!0-9]*) echo "get_i_arr_el: Error: no index specified or '$___index' is not a nonnegative integer." >&2; return 1; esac

	eval "$___out_var_name=\"\$___emu_i_${___arr_name}_${___index}\""
	unset ___index ___out_var_name
}



# declare an emulated associative array while populating elements
# 1 - array name
# all other args - 'key=value' pairs
declare_a_arr() {
	[ $# -lt 1 ] && { echo "declare_a_arr: Error: '$*': $# - not enough arguments." >&2; return 1; }
	___arr_name="$1"; shift
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "declare_a_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___keys=\"\$___emu_a_${___arr_name}_keys\""

	for ___key in $___keys; do
		unset "___emu_a_${___arr_name}_${___key}"
	done
	unset ___keys "___emu_a_${___arr_name}_keys"

	if [ -n "$*" ]; then
		for ___pair in "$@"; do
			case "$___pair" in *=*) ;; *) echo "declare_a_arr: Error: '$___pair' is not a 'key=value' pair." >&2; return 1 ;; esac
			___key="${___pair%%=*}"
			___val="$___delim${___pair#*=}"
			case "$___key" in *[!A-Za-z0-9_]*) echo "declare_a_arr: Error: invalid key '$___key'." >&2; return 1; esac
			eval "___emu_a_${___arr_name}_${___key}=\"$___val\""
			eval "_${___arr_name}_${___key}_=1"
			___keys="$___keys$___key$___newline"
		done
	fi

	___keys="$(printf '%s\n' "$___keys" | sort -u)"
	eval "___emu_a_${___arr_name}_keys=\"$___keys\""
	eval "___emu_a_${___arr_name}_sorted=1"

	unset ___val ___key ___keys
	return 0
}

# get all values from an emulated associative array (alphabetically sorted by key)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_a_arr_values() {
	[ $# -ne 2 ] && { echo "get_a_arr_all: Error: '$*': $# - wrong number of arguments." >&2; return 1; }
	___arr_name="$1"; ___out_var_name="$2"; ___values=''
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_a_arr_all: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___sorted=\"\$___emu_a_${___arr_name}_sorted\""
	if [ -z "$___sorted" ]; then
		___keys="$(eval "printf '%s\n' \"\$___emu_a_${___arr_name}_keys\"" | sort -u)$___newline"
		eval "___emu_a_${___arr_name}_keys=\"$___keys\""
		eval "___emu_a_${___arr_name}_sorted=1"
	else
		eval "___keys=\"\$___emu_a_${___arr_name}_keys\""
	fi

	___values="$(
		for ___key in $___keys; do
			eval "___val=\"\$___emu_a_${___arr_name}_${___key}\""
			# shellcheck disable=SC2030
			___val="${___val#"${___delim}"}"
			[ -n "$___val" ] && printf '%s ' "$___val"
		done
	)"

	eval "$___out_var_name=\"${___values% }\""
	unset ___keys ___key ___sorted ___values
	return 0
}

# get all keys from an emulated associative array (alphabetically sorted)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_a_arr_keys() {
	[ $# -ne 2 ] && { echo "get_a_arr_all_keys: Error: '$*': $# - wrong number of arguments." >&2; return 1; }
	___arr_name="$1"; ___out_var=$2; ___res_keys=''
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_a_arr_all_keys: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___sorted=\"\$___emu_a_${___arr_name}_sorted\""
	if [ -z "$___sorted" ]; then
		___keys="$(eval "printf '%s\n' \"\$___emu_a_${___arr_name}_keys\"" | sort -u)$___newline"
		eval "___emu_a_${___arr_name}_keys=\"$___keys\""
		eval "___emu_a_${___arr_name}_sorted=1"
	else
		eval "___keys=\"\$___emu_a_${___arr_name}_keys\""
	fi

	___res_keys="$(
		for ___key in $___keys; do
			eval "___val=\"\$___emu_a_${___arr_name}_${___key}\""
			# shellcheck disable=SC2031
			[ -n "$___val" ] && printf '%s ' "$___key"
		done
	)"

	eval "$___out_var=\"${___res_keys% }\""

	unset ___keys ___key ___res_keys ___sorted ___val
	return 0
}

# set a value in an emulated associative array
# 1 - array name
# 2 - 'key=value' pair
# no additional arguments are allowed
set_a_arr_el() {
	___arr_name="$1"; ___pair="$2"
	if [ $# -ne 2 ]; then echo "set_a_arr_el: Error: '$*': $# - wrong number of arguments." >&2; return 1; fi
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "set_a_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___pair" in *=*) ;; *) echo "set_a_arr_el: Error: '$___pair' is not a 'key=value' pair." >&2; return 1 ;; esac
	___key="${___pair%%=*}"
	___new_val="${___pair#*=}"
	case "$___key" in *[!A-Za-z0-9_]*) echo "set_a_arr_el: Error: invalid key '$___key'." >&2; return 1; esac

	eval "___old_val=\"\$___emu_a_${___arr_name}_${___key}\""

	if [ -z "$___old_val" ] && [ -n "$___key" ]; then
		eval "___emu_a_${___arr_name}_keys=\"\${___emu_a_${___arr_name}_keys}${___key}${___newline}\""
	fi

	eval "___emu_a_${___arr_name}_${___key}=\"${___delim}${___new_val}\""

	unset ___key ___new_val ___old_val 	"___emu_a_${___arr_name}_sorted"
	return 0
}

# get a value from an emulated associative array
# output is set as a value of a global variable
# 1 - array name
# 2 - key
# 3 - global variable name for output
# no additional arguments are allowed
get_a_arr_el() {
	if [ $# -ne 3 ]; then echo "get_a_arr_el: Error: '$*': $# - wrong number of arguments." >&2; return 1; fi
	___arr_name="$1"; ___key="$2"; ___out_var="$3"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_a_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___key" in *[!A-Za-z0-9_]*) echo "get_a_arr_el: Error: invalid key '$___key'." >&2; return 1; esac

	eval "___val=\"\$___emu_a_${___arr_name}_${___key}\""
	# shellcheck disable=SC2031
	eval "$___out_var=\"${___val#"${___delim}"}\""
	unset ___key ___out_var
}

clean_a_arr() {
	[ $# -ne 1 ] && { echo "clean_a_arr: Error: '$*': $# - wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "clean_a_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	eval "___keys=\"\$___emu_a_${___arr_name}_keys\""

	for ___key in $___keys; do
		unset "___emu_a_${___arr_name}_${___key}"
	done
	unset "___emu_a_${___arr_name}_keys" "___emu_a_${___arr_name}_sorted"
	unset ___keys ___key
}


___newline="
"
___delim="$(printf '\35')"