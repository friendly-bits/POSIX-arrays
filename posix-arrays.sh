#!/bin/sh

# posix-arrays.sh

# emulates arrays in POSIX shell

# each array element is stored in a variable named in the format '___[x]_[arr_name]_[key/index]'
# where [x] is either 'a' for associative array or 'i' for indexed array

# keys/indices are stored in a variable named in the format '___[x]_[arr_name]_keys' or '___[x]_[arr_name]_indices'
# array flags are stored in variables (true if variable is set): $___[x]_[arr_name]_sorted, $___[x]_[arr_name]_verified
# for indexed arrays, $_i_[arr_name]_h_index variable holds the highest index in the array if it's known


# unsets all variables used to store the array
unset_i_arr() {
	___me="unset_i_arr"
	[ $# -ne 1 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"
	check_arr_name || return 1

	do_unset_i_arr "${_arr_name}"
	unset "_i_${_arr_name}_ver_flag" "_i_${_arr_name}_sorted_flag"
}

# unsets all variables of an indexed array
# 1 - array name
do_unset_i_arr() {
	eval "_indices=\"\$_i_${1}_indices\""

	for _index in $_indices; do
		unset "_i_${1}_${_index}"
	done
	unset "_i_${1}_indices" "_i_${1}_h_index" _index _indices
}

# sorts and verifies indices of indexed array
# assigns the resulting indices to $_indices
# sets the 'sorted' and 'verified' flags in the array vars
# finds the max index and assigns to '_h_index' and to the array var
# caller should update the '_i_${_arr_name}_indices' variable externally
sort_verify_i_arr() {
	eval "_indices=\"\$_i_${_arr_name}_indices\"
		_sorted_flag=\"\$_i_${_arr_name}_sorted_flag\"
		_ver_flag=\"\$_i_${_arr_name}_ver_flag\""

	if [ -n "$_indices" ]; then
		if [ -z "$_sorted_flag" ] && [ -z "$_ver_flag" ]; then
			_indices="$(
				for _index in $_indices; do
					eval "___val=\"\$_i_${_arr_name}_${_index}\""
					[ -n "$___val" ] && printf '%s\n' "$_index"
				done | sort -nu
			)"
			[ -n "$_indices" ] && _indices="${_indices}$___newline"
			eval "_i_${_arr_name}_sorted_flag=1; _i_${_arr_name}_ver_flag=1"
		elif [ -n "$_sorted_flag" ] && [ -z "$_ver_flag" ]; then
			_indices="$(
				for _index in $_indices; do
					eval "___val=\"\$_i_${_arr_name}_${_index}\""
					[ -n "$___val" ] && printf '%s\n' "$_index"
				done
			)"
			[ -n "$_indices" ] && _indices="${_indices}$___newline"
			eval "_i_${_arr_name}_ver_flag=1"
		elif [ -z "$_sorted_flag" ] && [ -n "$_ver_flag" ]; then
			_indices="$(printf '%s\n' "$_indices" | sort -nu)$___newline"
			eval "_i_${_arr_name}_sorted_flag=1"
		fi
	fi

	[ -n "$_indices" ] && {
		_h_index="${_indices%"${___newline}"}"
		_h_index="${_h_index##*"${___newline}"}"
		eval "_i_${_arr_name}_h_index"='$_h_index'
	} || { _h_index="-1"; unset "_i_${_arr_name}_h_index"; }

	unset ___val _sorted_flag _ver_flag _index
}

# declare an indexed array while populating first elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - new array values
declare_i_arr() {
	___me="declare_i_arr"
	[ $# -lt 1 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; shift
	check_arr_name || return 1

	do_unset_i_arr "${_arr_name}"

	_index=0; _indices=''
	for ___val in "$@"; do
		eval "_i_${_arr_name}_${_index}"='$_el_set_flag$___val'
		_indices="$_indices$_index$___newline"
		_index=$((_index + 1))
	done
	_index=$((_index - 1))

	[ "$_index" = "-1" ] && _index=''

	eval "_i_${_arr_name}_h_index"='$_index'"
		_i_${_arr_name}_indices"='$_indices'"
		_i_${_arr_name}_sorted_flag=1;
		_i_${_arr_name}_ver_flag=1"
	unset ___val _index _indices
	return 0
}

# initialize an indexed array while assigning the same string to N first indices (1-based)
# the point is to speed up setting elements at a later time
# resets all previous elements of the array if it already exists
# 1 - array name
# 2 - number of elements to initialize
# 3 - string to assign (if not specified, assigns an empty string)
init_i_arr() {
	___me="init_i_arr"
	[ $# -lt 2 ] || [ $# -gt 3 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; _el_num="$2"; _val="$3"
	check_arr_name || return 1
	_index="$_el_num"; check_index || return 1
	_last_index=$((_el_num-1))

	do_unset_i_arr "${_arr_name}"

	if [ $_last_index != "-1" ]; then
		_index=0; _indices=''
		while [ $_index -le "$_last_index" ]; do
			eval "_i_${_arr_name}_${_index}"='$_el_set_flag$_val'
			_indices="$_indices$_index$___newline"
			_index=$((_index + 1))
		done
		_index=$((_index - 1))
		eval "_i_${_arr_name}_h_index"='$_index'"
			_i_${_arr_name}_indices"='$_indices'"
			_i_${_arr_name}_sorted_flag=1;
			_i_${_arr_name}_ver_flag=1"
		unset _index _indices
	fi

	unset _last_index
	return 0
}

# read lines from input string into an indexed array
# unsets all previous elements of the array if it already exists
# 1 - array name
# 2 - newline-separated string
# no additional arguments are allowed
read_i_arr() {
	___me="read_i_arr"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; ___lines="$2"
	check_arr_name || return 1

	do_unset_i_arr "${_arr_name}"

	_index=0
    IFS_OLD="$IFS"
    IFS="$___newline"
	for ___line in $___lines; do
		eval "_i_${_arr_name}_${_index}"='$_el_set_flag$___line'
		_indices="$_indices$_index$___newline"
		_index=$((_index + 1))
	done
    IFS="$IFS_OLD"

	_index=$((_index - 1))
	[ "$_index" = "-1" ] && _index=''

	eval "_i_${_arr_name}_h_index"='$_index'"
		_i_${_arr_name}_indices"='$_indices'"
		_i_${_arr_name}_sorted_flag=1
		_i_${_arr_name}_ver_flag=1"

	unset ___line ___lines _index _indices _input_file
	return 0
}

# get all values from an indexed array (sorted by index)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_values() {
	___me="get_i_arr_values"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; _out_var="$2"; ___values=''
	check_arr_name || return 1
	check_var_name || return 1

	# populates the $_indices variable and sets the 'sorted' and 'verified' flags
	sort_verify_i_arr
	eval "_i_${_arr_name}_indices"='$_indices'

	[ -n "$_indices" ] && ___values="$(
	for _index in $_indices; do
		eval "printf '%s ' \"\${_i_${_arr_name}_${_index}#$_el_set_flag}\""
	done
	)"

	eval "$_out_var"='${___values% }'

	unset ___values _indices _index _out_var
	return 0
}

# get all indices from an indexed array (sorted)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_indices() {
	___me="get_i_arr_indices"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1" _out_var_name="$2"
	check_arr_name || return 1
	check_var_name || return 1

	# populates the $_indices variable and sets the 'sorted' and 'verified' flags
	sort_verify_i_arr
	eval "_i_${_arr_name}_indices"='$_indices'

	# shellcheck disable=SC2086
	_indices="$(printf '%s ' $_indices)" # no quotes on purpose

	eval "$_out_var_name"='${_indices% }'

	unset _indices _out_var_name
	return 0
}

# add a new element to an indexed array and set its value
# 1 - array name
# 2 - value
# no additional arguments are allowed
add_i_arr_el() {
	___me="add_i_arr_el"
	_arr_name="$1"; ___new_val="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_arr_name || return 1

	eval "_h_index=\"\$_i_${_arr_name}_h_index\""
	if [ -z "$_h_index" ]; then
		# populates the $_indices and $_h_index variables and sets the 'sorted' and 'verified' flags
		sort_verify_i_arr
		_index=$((_h_index + 1))
		eval "_i_${_arr_name}_indices"='${_indices}${_index}${___newline}'
	else
		_index=$((_h_index + 1))
		eval "_i_${_arr_name}_indices=\"\${_i_${_arr_name}_indices}${_index}${___newline}\""
	fi

	eval "_i_${_arr_name}_h_index"='$_index'"
		_i_${_arr_name}_${_index}"='$_el_set_flag$___new_val'

	unset ___new_val _indices _index _h_index
	return 0
}

# unset an element of an indexed array
# 1 - array name
# 2 - index
# no additional arguments are allowed
unset_i_arr_el() {
	___me="unset_i_arr_el"
	_arr_name="$1"; _index="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_arr_name || return 1
	check_index || return 1

	eval "___old_val=\"\$_i_${_arr_name}_${_index}\"
		_h_index=\"\$_i_${_arr_name}_h_index\"
		_sorted_flag=\"\$_i_${_arr_name}_sorted_flag\""

	if [ -n "$___old_val" ]; then
		unset "_i_${_arr_name}_${_index}"
		if [ "$_index" = "$_h_index" ] && [ -n "$_sorted_flag" ]; then
			eval "_i_${_arr_name}_indices=\"\${_i_${_arr_name}_indices%${_index}${___newline}}\"
				_i_${_arr_name}_h_index=\"\${_i_${_arr_name}_indices%${___newline}}\"
				_i_${_arr_name}_h_index=\"\${_i_${_arr_name}_h_index##*${___newline}}\""
		else
			unset "_i_${_arr_name}_ver_flag"
			[ "$_index" = "$_h_index" ] && unset "_i_${_arr_name}_h_index"
		fi
	fi

	unset _index ___old_val _h_index _sorted_flag
	return 0
}

# get maximum index of an indexed array
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_max_index() {
	___me="get_i_arr_max_index"
	_arr_name="$1"; _out_var_name="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_arr_name || return 1
	check_var_name || return 1

	eval "_h_index=\"\$_i_${_arr_name}_h_index\""
	if [ -z "$_h_index" ]; then
		# populates the $_indices variable and sets the 'sorted' and 'verified' flags
		sort_verify_i_arr
		eval "_i_${_arr_name}_indices"='${_indices}'
		if [ -z "$_indices" ]; then
			unset "$_out_var_name" "_i_${_arr_name}_indices" _indices _h_index _out_var_name
			no_elements; return 1
		fi
	fi

	eval "_i_${_arr_name}_h_index"='$_h_index'"
		$_out_var_name"='$_h_index'

	unset _indices _h_index _out_var_name
	return 0
}

# get value of the last element in an indexed array
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_last_val() {
	___me="get_i_arr_last_val"
	_arr_name="$1"; _out_var_name="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_arr_name || return 1
	check_var_name || return 1

	eval "_h_index=\"\$_i_${_arr_name}_h_index\""
	if [ -z "$_h_index" ]; then
		# populates the $_indices and $_h_index variables and sets the 'sorted' and 'verified' flags
		sort_verify_i_arr
		eval "_i_${_arr_name}_indices"='${_indices}'
		if [ -z "$_indices" ]; then
			unset "$_out_var_name" "_i_${_arr_name}_indices" _indices _h_index _out_var_name
			no_elements; return 1
		fi
	fi

	eval "_i_${_arr_name}_h_index"='$_h_index'"
		$_out_var_name=\"\${_i_${_arr_name}_${_h_index}#$_el_set_flag}\""

	unset _indices _h_index _out_var_name
	return 0
}

# get the element count of an indexed array
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_el_cnt() {
	___me="get_i_arr_el_cnt"
	_arr_name="$1"; _out_var_name="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_arr_name || return 1
	check_var_name || return 1

	# populates the $_indices variable and sets the 'sorted' and 'verified' flags
	sort_verify_i_arr
	eval "_i_${_arr_name}_indices"='${_indices}'

	i=0
	for _ind in $_indices; do i=$((i+1)); done

	eval "$_out_var_name"='$i'

	unset _indices _out_var_name i _ind
	return 0
}

# set an element in an indexed array
# 1 - array name
# 2 - index
# 3 - value (if no value, unsets the element)
# no additional arguments are allowed
set_i_arr_el() {
	___me="set_i_arr_el"
	_arr_name="$1"; _index="$2"; ___new_val="$3"
	if [ $# -lt 2 ] || [ $# -gt 3 ]; then  wrongargs "$@"; return 1; fi
	check_arr_name || return 1
	check_index || return 1

	eval "___old_val=\"\$_i_${_arr_name}_${_index}\""
	if [ -z "$___old_val" ]; then
		eval "_i_${_arr_name}_indices=\"\${_i_${_arr_name}_indices}${_index}${___newline}\"
			_i_${_arr_name}_${_index}"='$_el_set_flag$___new_val'"
			_h_index=\"\$_i_${_arr_name}_h_index\""
		if [ -n "$_h_index" ] && [ "$_index" -gt  "$_h_index" ]; then
			eval "_i_${_arr_name}_h_index"='$_index'
		else
			unset "_i_${_arr_name}_sorted_flag"
		fi
	else
		eval "_i_${_arr_name}_${_index}"='$_el_set_flag$___new_val'
	fi

	unset _index ___new_val ___old_val _h_index
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
	[ $# -ne 3 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; _index="$2"; _out_var_name="$3"
	check_arr_name || return 1
	check_var_name || return 1
	check_index || return 1

	eval "$_out_var_name=\"\${_i_${_arr_name}_${_index}#$_el_set_flag}\""
	unset _index _out_var_name
}


# unsets all variables used to store the array
unset_a_arr() {
	___me="get_a_arr_val"
	[ $# -ne 1 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"
	check_arr_name || return 1

	do_unset_a_arr "${_arr_name}"

	unset "_a_${_arr_name}_sorted_flag" "_a_${_arr_name}_ver_flag"
	unset ___keys ___key
}

# unsets all variables of an associative array
# 1 - array name
do_unset_a_arr() {
	eval "___keys=\"\$_a_${1}___keys\""

	for ___key in $___keys; do
		unset "_a_${1}_${___key}"
	done
	unset "_a_${1}___keys" ___key ___keys
}

# sorts and verifies keys of an associative array
# assigns the resulting keys to $___keys
# updates the '$_a_${_arr_name}____keys' variable
# sets the 'sorted' and 'verified' flags
sort_verify_a_arr() {
	eval "___keys=\"\$_a_${_arr_name}___keys\"
		_sorted_flag=\"\$_a_${_arr_name}_sorted_flag\"
		_ver_flag=\"\$_a_${_arr_name}_ver_flag\""
	if [ -n "$___keys" ]; then
		if [ -z "$_sorted_flag" ] && [ -z "$_ver_flag" ]; then
			___keys="$(
				for ___key in $___keys; do
					eval "___val=\"\$_a_${_arr_name}_${___key}\""
					[ -n "$___val" ] && printf '%s\n' "$___key"
				done | sort -u
			)"
			[ -n "$___keys" ] && ___keys="${___keys}$___newline"
			eval "_a_${_arr_name}_sorted_flag=1; _a_${_arr_name}_ver_flag=1"
		elif [ -n "$_sorted_flag" ] && [ -z "$_ver_flag" ]; then
			___keys="$(
				for ___key in $___keys; do
					eval "___val=\"\$_a_${_arr_name}_${___key}\""
					[ -n "$___val" ] && printf '%s\n' "$___key"
				done
			)"
			[ -n "$___keys" ] && ___keys="${___keys}$___newline"
			eval "_a_${_arr_name}_ver_flag=1"
		elif [ -z "$_sorted_flag" ] && [ -n "$_ver_flag" ]; then
			___keys="$(printf '%s\n' "$___keys" | sort -u)$___newline"
			eval "_a_${_arr_name}_sorted_flag=1"
		fi
		eval "_a_${_arr_name}___keys"='$___keys'
	fi
	unset ___val _sorted_flag _ver_flag ___key
}

# declare an associative array while populating elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - 'key=value' pairs
declare_a_arr() {
	___me="declare_a_arr"
	[ $# -lt 1 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; shift
	check_arr_name || return 1

	do_unset_a_arr "${_arr_name}"

	if [ -n "$*" ]; then
		for ___pair in "$@"; do
			check_pair || return 1
			___key="${___pair%%=*}"
			___val="$_el_set_flag${___pair#*=}"
			check_key || return 1
			eval "_a_${_arr_name}_${___key}"='$___val'
			___keys="$___keys$___key$___newline"
		done
	fi

	[ -n "$___keys" ] && ___keys="$(printf '%s\n' "$___keys" | sort -u)$___newline"
	eval "_a_${_arr_name}___keys"='$___keys'"; _a_${_arr_name}_sorted_flag=1; _a_${_arr_name}_ver_flag=1"
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
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; _out_var_name="$2"; ___values=''
	check_arr_name || return 1
	check_var_name || return 1

	sort_verify_a_arr
	___values="$(
		for ___key in $___keys; do
		eval IFS='$_el_set_flag'"; printf '%s '\$_a_${_arr_name}_${___key}" # no extra quotes on purpose
		done
	)"

	eval "$_out_var_name"='${___values% }'
	unset ___keys ___key ___values
	return 0
}

# get all keys from an associative array (alphabetically sorted)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_a_arr_keys() {
	___me="get_a_arr_keys"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; _out_var=$2
	check_arr_name || return 1
	check_var_name || return 1

	sort_verify_a_arr
	# shellcheck disable=SC2086
	___keys="$(printf '%s ' $___keys)"
	eval "$_out_var"='${___keys% }'

	unset ___keys _out_var
	return 0
}

# get the element count of an associative array
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_a_arr_el_cnt() {
	___me="get_a_arr_el_cnt"
	_arr_name="$1"; _out_var_name="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_arr_name || return 1
	check_var_name || return 1

	# populates the $___keys variable and sets the 'sorted' and 'verified' flags
	sort_verify_a_arr

	i=0
	for ___key in $___keys; do i=$((i+1)); done

	eval "$_out_var_name"='$i'

	unset ___keys ___key _out_var_name i
	return 0
}

# set an element in an associative array
# if value is an empty string, assings empty string to the key
# 1 - array name
# 2 - 'key=value' pair
# no additional arguments are allowed
set_a_arr_el() {
	___me="set_a_arr_el"
	_arr_name="$1"; ___pair="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_arr_name || return 1
	check_pair || return 1
	___key="${___pair%%=*}"
	___new_val="${___pair#*=}"
	check_key || return 1

	eval "___old_val=\"\$_a_${_arr_name}_${___key}\""
	[ -z "$___old_val" ] && unset "_a_${_arr_name}_sorted_flag"

	eval "_a_${_arr_name}___keys=\"\${_a_${_arr_name}___keys}${___key}${___newline}\""
	eval "_a_${_arr_name}_${___key}"='${_el_set_flag}${___new_val}'

	unset ___key ___new_val ___old_val
	return 0
}

# unset an element in an associative array
# 1 - array name
# 2 - key
# no additional arguments are allowed
unset_a_arr_el() {
	___me="unset_a_arr_el"
	_arr_name="$1"; ___key="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_arr_name || return 1
	check_key || return 1

	eval "___old_val=\"\$_a_${_arr_name}_${___key}\""

	[ -n "$___old_val" ] && unset "_a_${_arr_name}_${___key}" "_a_${_arr_name}_ver_flag"

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
	[ $# -ne 3 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; ___key="$2"; _out_var="$3"
	check_arr_name || return 1
	check_key || return 1
	check_var_name || return 1

	eval "___val=\"\$_a_${_arr_name}_${___key}\""
	# shellcheck disable=SC2031
	eval "$_out_var"='${___val#"${_el_set_flag}"}'
	unset ___key _out_var
}


no_elements() { echo "$___me: Error: array '$_arr_name' has no elements." >&2; }
check_arr_name() { case "$_arr_name" in *[!A-Za-z0-9_]* ) echo "$___me: Error: invalid array name '$_arr_name'." >&2; return 1; esac; }
check_var_name() { case "$_out_var" in *[!A-Za-z0-9_]* ) echo "$___me: Error: invalid output variable name '$_out_var'." >&2; return 1; esac; }
check_key() { case "$___key" in *[!A-Za-z0-9_]* ) echo "$___me: Error: invalid key '$___key'." >&2; return 1; esac; }
check_index() {	case "$_index" in *[!0-9]* ) echo "$___me: Error: '$_index' is not a nonnegative integer." >&2; return 1; esac; }
check_pair() { case "$___pair" in *=* ) ;; * ) echo "$___me: Error: '$___pair' is not a 'key=value' pair." >&2; return 1; esac; }
wrongargs() { echo "$___me: Error: '$*': wrong number of arguments '$#'." >&2; }


___newline="
"
_el_set_flag="$(printf '\35')"

