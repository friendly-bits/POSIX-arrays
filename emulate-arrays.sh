#!/bin/sh

# emulate-arrays.sh

# emulates arrays in POSIX shell

# each array element is stored in a variable named in the format '___[x]_[arr_name]_[key/index]'
# where [x] is either 'a' for associative array or 'i' for indexed array

# keys/indices are stored in a variable named in the format '___[x]_[arr_name]_keys' or '___[x]_[arr_name]_indices'
# array flags are stored in variables (true if variable is set): $___[x]_[arr_name]_sorted, $___[x]_[arr_name]_verified
# for indexed arrays, $___i_[arr_name]_high_index variable holds the highest index in the array if it's known


# declare an indexed array while populating first elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - array values
declare_i_arr() {
	___me="declare_i_arr"
	[ $# -lt 1 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1"; shift
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac

	eval "___indices=\"\$___i_${___arr_name}_indices\""

	for ___index in $___indices; do
		unset "___i_${___arr_name}_${___index}"
	done
	unset "___i_${___arr_name}_indices"
	unset ___indices "___i_${___arr_name}_high_index"

	___index=0
	if [ -n "$*" ]; then
		for ___val in "$@"; do
			eval "___i_${___arr_name}_${___index}=\"$___val\""
			___indices="$___indices$___index$___newline"
			___index=$((___index + 1))
		done
	fi

	eval "___i_${___arr_name}_high_index=\"$((___index - 1))\";
		___i_${___arr_name}_indices=\"$___indices\";
		___i_${___arr_name}_sorted=1;
		___i_${___arr_name}_verified=1"
	unset ___val ___index ___indices
	return 0
}

# read lines from input string into an indexed array
# unsets all previous elements of the array if it already exists
# 1 - array name
# 2 - newline-separated string
# no additional arguments are allowed
read_i_arr() {
	___me="read_i_arr"
	[ $# -ne 2 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1"; ___lines="$2"
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac

	eval "___indices=\"\$___i_${___arr_name}_indices\""

	for ___index in $___indices; do
		unset "___i_${___arr_name}_${___index}"
	done
	unset "___i_${___arr_name}_indices" ___indices

	___index=0
    IFS_OLD="$IFS"
    IFS="$___newline"
	for ___line in $___lines; do
		eval "___i_${___arr_name}_${___index}=\"$___line\""
		___indices="$___indices$___index$___newline"
		___index=$((___index + 1))
	done
    IFS="$IFS_OLD"

	eval "___i_${___arr_name}_high_index=\"$((___index - 1))\";
		___i_${___arr_name}_indices=\"$___indices\";
		___i_${___arr_name}_sorted=1;
		___i_${___arr_name}_verified=1"

	unset ___line ___lines ___index ___indices ___input_file
	return 0
}

clean_i_arr() {
	___me="clean_i_arr"
	[ $# -ne 1 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac

	eval "___indices=\"\$___i_${___arr_name}_indices\""

	for ___index in $___indices; do
		unset "___i_${___arr_name}_${___index}"
	done
	unset ___indices ___index "___i_${___arr_name}_high_index" "___i_${___arr_name}_indices"
}

# get all values from an indexed array (sorted by index)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_values() {
	___me="get_i_arr_values"
	[ $# -ne 2 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1"; ___out_var="$2"; ___values=''
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac

	# populates $___indices variable and sets the 'sorted' and 'verified' flags
	___sort_and_verify_i_arr
	eval "___i_${___arr_name}_indices=\"$___indices\""

	[ -n "$___indices" ] && ___values="$(
	for ___index in $___indices; do
		eval "printf '%s ' \"\$___i_${___arr_name}_${___index}\""
	done
	)"

	eval "$___out_var=\"${___values% }\""

	unset ___values ___indices ___index ___val ___sorted ___out_var
	return 0
}

# get all indices from an indexed array (sorted)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_indices() {
	___me="get_i_arr_indices"
	[ $# -ne 2 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1" ___out_var_name="$2"
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac

	# populates $___indices variable and sets the 'sorted' and 'verified' flags
	___sort_and_verify_i_arr
	eval "___i_${___arr_name}_indices=\"$___indices\""

	# shellcheck disable=SC2086
	___res_indices="$(printf '%s ' $___indices)"

	eval "$___out_var_name=\"${___res_indices% }\""

	unset ___indices ___res_indices ___index ___sorted ___out_var_name ___val
	return 0
}

# sorts and verifies indices of indexed array
# assigns the resulting indices to $___indices
# sets the 'sorted' and 'verified' flags
___sort_and_verify_i_arr() {
	eval "___indices=\"\$___i_${___arr_name}_indices\";
		___sorted=\"\$___i_${___arr_name}_sorted\";
		___verified=\"\$___i_${___arr_name}_verified\""
	if [ -n "$___indices" ]; then
		if [ -z "$___sorted" ] && [ -z "$___verified" ]; then
			___indices="$(
				for ___index in $___indices; do
					eval "___val=\"\$___i_${___arr_name}_${___index}\""
					[ -n "$___val" ] && printf '%s\n' "$___index"
				done | sort -nu
			)"
			[ -n "$___indices" ] && ___indices="${___indices#"$___newline"}$___newline"
			eval "___i_${___arr_name}_sorted=1; ___i_${___arr_name}_verified=1"
		elif [ -n "$___sorted" ] && [ -z "$___verified" ]; then
			___indices="$(
				for ___index in $___indices; do
					eval "___val=\"\$___i_${___arr_name}_${___index}\""
					[ -n "$___val" ] && printf '%s\n' "$___index"
				done
			)"
			[ -n "$___indices" ] && ___indices="${___indices#"$___newline"}$___newline"
			eval "___i_${___arr_name}_verified=1"
		elif [ -z "$___sorted" ] && [ -n "$___verified" ]; then
			___indices="$(printf '%s\n' "$___indices" | sort -nu)$___newline"
			eval "___i_${___arr_name}_sorted=1"
		fi
	fi
}

# add a new element to an indexed array and set its value
# 1 - array name
# 2 - value
# no additional arguments are allowed
add_i_arr_el() {
	___me="add_i_arr_el"
	___arr_name="$1"; ___new_val="$2"
	[ $# -ne 2 ] && { eval "$___wrongargs" >&2; return 1; }
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac

	eval "___high_index=\"\$___i_${___arr_name}_high_index\""
	if [ -z "$___high_index" ]; then
		# populates $___indices variable and sets the 'sorted' and 'verified' flags
		___sort_and_verify_i_arr
		[ -n "$___indices" ] && {
			___high_index="${___indices%"$___newline"}"
			___high_index="${___high_index##*"$___newline"}"
		} || ___high_index="-1"

		___index=$((___high_index + 1))
		eval "___i_${___arr_name}_indices=\"${___indices}${___index}${___newline}\""
	else
		___index=$((___high_index + 1))
		eval "___i_${___arr_name}_indices=\"\${___i_${___arr_name}_indices}${___index}${___newline}\""
	fi

	eval "___i_${___arr_name}_high_index=\"$___index\";
		___i_${___arr_name}_${___index}=\"$___new_val\""

	unset ___new_val ___val ___indices ___index ___high_index
	return 0
}

# set an element in an indexed array
# 1 - array name
# 2 - index
# 3 - value (if no value, unsets the element)
# no additional arguments are allowed
set_i_arr_el() {
	___me="add_i_arr_el"
	___arr_name="$1"; ___index="$2"; ___new_val="$3"
	if [ $# -lt 2 ] || [ $# -gt 3 ]; then eval "$___wrongargs" >&2; return 1; fi
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac
	case "$___index" in *[!0-9]*) eval "$___wrongindex" >&2; return 1 ; esac

	eval "___old_val=\"\$___i_${___arr_name}_${___index}\""
	if [ -z "$___old_val" ] && [ -n "$___new_val" ]; then
		eval "___i_${___arr_name}_indices=\"\${___i_${___arr_name}_indices}${___index}${___newline}\";
			___i_${___arr_name}_${___index}=\"$___new_val\";
			___high_index=\"\$___i_${___arr_name}_high_index\""
		if [ -n "$___high_index" ] && [ "$___index" -gt  "$___high_index" ]; then
			eval "___i_${___arr_name}_high_index=$___index"
		else
			unset "___i_${___arr_name}_sorted"
		fi
	elif [ -n "$___old_val" ] && [ -z "$___new_val" ]; then
		unset "___i_${___arr_name}_verified" "___i_${___arr_name}_${___index}"
		eval "___high_index=\"\$___i_${___arr_name}_high_index\""
		[ "$___index" =  "$___high_index" ] && unset "___i_${___arr_name}_high_index"
	elif [ -n "$___old_val" ] && [ -n "$___new_val" ]; then
		eval "___i_${___arr_name}_${___index}=\"$___new_val\""
	fi

	unset ___index ___new_val ___old_val ___high_index
	return 0
}

# get a value from an indexed array
# output is set as a value of a global variable
# 1 - array name
# 2 - index
# 3 - global variable name for output
# no additional arguments are allowed
get_i_arr_val() {
	___me="get_i_arr_val"
	[ $# -ne 3 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1"; ___index="$2"; ___out_var_name="$3"
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac
	case "$___index" in *[!0-9]*) eval "$___wrongindex" >&2; return 1; esac

	eval "$___out_var_name=\"\$___i_${___arr_name}_${___index}\""
	unset ___index ___out_var_name
}



# declare an associative array while populating elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - 'key=value' pairs
declare_a_arr() {
	___me="declare_a_arr"
	[ $# -lt 1 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1"; shift
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac

	eval "___keys=\"\$___a_${___arr_name}_keys\""

	for ___key in $___keys; do
		unset "___a_${___arr_name}_${___key}"
	done
	unset ___keys "___a_${___arr_name}_keys"

	if [ -n "$*" ]; then
		for ___pair in "$@"; do
			case "$___pair" in *=*) ;; *) eval "$___wrongpair" >&2; return 1 ;; esac
			___key="${___pair%%=*}"
			___val="$___delim${___pair#*=}"
			case "$___key" in *[!A-Za-z0-9_]*) eval "$___wrongkey" >&2; return 1; esac
			eval "___a_${___arr_name}_${___key}=\"$___val\""
			___keys="$___keys$___key$___newline"
		done
	fi

	[ -n "$___keys" ] && ___keys="$(printf '%s\n' "$___keys" | sort -u)$___newline"
	eval "___a_${___arr_name}_keys=\"$___keys\"; ___a_${___arr_name}_sorted=1; ___a_${___arr_name}_verified=1"
	unset ___val ___key ___keys
	return 0
}

# get all values from an associative array (alphabetically sorted by key)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_a_arr_values() {
	___me="get_a_arr_values"
	[ $# -ne 2 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1"; ___out_var_name="$2"; ___values=''
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac

	___sort_and_verify_a_arr
	___values="$(
		for ___key in $___keys; do
		eval "IFS=\"$___delim\"; printf '%s '\$___a_${___arr_name}_${___key}"
		done
	)"

	eval "$___out_var_name=\"${___values% }\""
	unset ___keys ___key ___sorted ___values
	return 0
}

# sorts and verifies keys of an associative array
# assigns the resulting keys to $___keys
# sets the 'sorted' flag
___sort_and_verify_a_arr() {
	eval "___keys=\"\$___a_${___arr_name}_keys\";
		___sorted=\"\$___a_${___arr_name}_sorted\";
		___verified=\"\$___a_${___arr_name}_verified\""
	if [ -n "$___keys" ]; then
		if [ -z "$___sorted" ] && [ -z "$___verified" ]; then
			___keys="$(
				for ___key in $___keys; do
					eval "___val=\"\$___a_${___arr_name}_${___key}\""
					[ -n "$___val" ] && printf '%s\n' "$___key"
				done | sort -u
			)"
			[ -n "$___keys" ] && ___keys="${___keys#"$___newline"}$___newline"
			eval "___a_${___arr_name}_sorted=1; ___a_${___arr_name}_verified=1"
		elif [ -n "$___sorted" ] && [ -z "$___verified" ]; then
			___keys="$(
				for ___key in $___keys; do
					eval "___val=\"\$___a_${___arr_name}_${___key}\""
					[ -n "$___val" ] && printf '%s\n' "$___key"
				done
			)"
			[ -n "$___keys" ] && ___keys="${___keys#"$___newline"}$___newline"
			eval "___a_${___arr_name}_verified=1"
		elif [ -z "$___sorted" ] && [ -n "$___verified" ]; then
			___keys="$(printf '%s\n' "$___keys" | sort -u)$___newline"
			eval "___a_${___arr_name}_sorted=1"
		fi
		eval "___a_${___arr_name}_keys=\"$___keys\""
	fi
}

# get all keys from an associative array (alphabetically sorted)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_a_arr_keys() {
	___me="get_a_arr_keys"
	[ $# -ne 2 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1"; ___out_var=$2
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac

	___sort_and_verify_a_arr
	# shellcheck disable=SC2086
	___keys="$(printf '%s ' $___keys)"
	eval "$___out_var=\"${___keys% }\""

	unset ___keys ___key ___keys ___sorted ___val
	return 0
}

# set an element in an associative array
# if value is an empty string, assings empty string to the key
# 1 - array name
# 2 - 'key=value' pair
# no additional arguments are allowed
set_a_arr_el() {
	___me="set_a_arr_el"
	___arr_name="$1"; ___pair="$2"
	[ $# -ne 2 ] && { eval "$___wrongargs" >&2; return 1; }
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac
	case "$___pair" in *=*) ;; *) eval "$___wrongpair" >&2; return 1 ; esac
	___key="${___pair%%=*}"
	___new_val="${___pair#*=}"
	case "$___key" in *[!A-Za-z0-9_]*) eval "$___wrongkey" >&2; return 1; esac

	eval "___old_val=\"\$___a_${___arr_name}_${___key}\""
	[ -z "$___old_val" ] && unset "___a_${___arr_name}_sorted"

	eval "___a_${___arr_name}_keys=\"\${___a_${___arr_name}_keys}${___key}${___newline}\""
	eval "___a_${___arr_name}_${___key}=\"${___delim}${___new_val}\""

	unset ___key ___new_val ___old_val
	return 0
}

# unset an element in an associative array
# 1 - array name
# 2 - key
# no additional arguments are allowed
unset_a_arr_el() {
	___me="unset_a_arr_el"
	___arr_name="$1"; ___key="$2"
	[ $# -ne 2 ] && { eval "$___wrongargs" >&2; return 1; }
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac
	case "$___key" in *[!A-Za-z0-9_]*) eval "$___wrongkey" >&2; return 1; esac

	eval "___old_val=\"\$___a_${___arr_name}_${___key}\""

	[ -n "$___old_val" ] && unset "___a_${___arr_name}_${___key}" "___a_${___arr_name}_verified"

	unset ___key ___new_val ___old_val
	return 0
}

# get a value from an emulated associative array
# output is set as a value of a global variable
# 1 - array name
# 2 - key
# 3 - global variable name for output
# no additional arguments are allowed
get_a_arr_val() {
	___me="get_a_arr_val"
	[ $# -ne 3 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1"; ___key="$2"; ___out_var="$3"
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac
	case "$___key" in *[!A-Za-z0-9_]*) eval "$___wrongkey" >&2; return 1; esac

	eval "___val=\"\$___a_${___arr_name}_${___key}\""
	# shellcheck disable=SC2031
	eval "$___out_var=\"${___val#"${___delim}"}\""
	unset ___key ___out_var
}

clean_a_arr() {
	___me="get_a_arr_val"
	[ $# -ne 1 ] && { eval "$___wrongargs" >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) eval "$___wrongname" >&2; return 1; esac

	eval "___keys=\"\$___a_${___arr_name}_keys\""
	for ___key in $___keys; do
		unset "___a_${___arr_name}_${___key}"
	done
	unset "___a_${___arr_name}_keys" "___a_${___arr_name}_sorted" "___a_${___arr_name}_verified"
	unset ___keys ___key
}


___newline="
"
___delim="$(printf '\35')"
___wrongargs="echo \"\$___me: Error: '\$*': \$# - wrong number of arguments.\""
___wrongname="echo \"\$___me: Error: invalid array name '\$___arr_name'.\""
___wrongkey="echo \"\$___me: Error: invalid key '\$___key'.\""
___wrongindex="echo \"\$___me: Error: no index specified or '\$___index' is not a nonnegative integer.\""
___wrongpair="echo \"\$___me: Error: '\$___pair' is not a 'key=value' pair.\""
