#!/bin/sh

# posix-arrays.sh

# emulates arrays in POSIX shell

# each array element is stored in a variable named in the format '_[x]_[arr_name]_[key/index]'
# where [x] is either 'a' for associative array or 'i' for indexed array

# keys/indices are stored in a variable named in the format '_[x]_[arr_name]_keys' or '_[x]_[arr_name]_indices'
# array 'sorted' flag (1=true, 0=false) is stored in variable: $_[x]_[arr_name]_sorted_flag
# for indexed arrays, $_i_[arr_name]_h_index variable holds the highest index in the array if it's known


# unsets all variables used to store an indexed array
# 1 - array name
unset_i_arr() {
	___me="unset_i_arr"
	[ $# != 1 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"
	check_strings "$_arr_name" || return 1

	do_unset_i_arr "${_arr_name}"
	eval "_i_${_arr_name}_sorted_flag=0"
}

# backend function
# unsets all variables of an indexed array
# 1 - array name
do_unset_i_arr() {
	eval "_indices=\"\$_i_${1}_indices\""

	for _index in $_indices; do
		unset "_i_${1}_${_index}"
	done
	unset "_i_${1}_indices" "_i_${1}_h_index"
}

# wrapper function for __sort_i_arr, intended as a user interface
# 1 - array name
sort_i_arr() {
	___me="sort_i_arr"
	[ $# != 1 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"
	check_strings "$_arr_name" || return 1
	__sort_i_arr
	eval "_i_${_arr_name}_indices"='$_indices'
	return 0
}

# backend function
# sorts indices of indexed array
# assigns the resulting indices to $_indices
# sets the 'sorted' flag
# finds the max index and assigns to variables '_h_index' and '_i_${arr_name}_h_index'
# caller should update the '_i_${_arr_name}_indices' variable externally
__sort_i_arr() {
	eval "_indices=\"\$_i_${_arr_name}_indices\"
		_sorted_flag=\"\$_i_${_arr_name}_sorted_flag\""

	# if $_sorted_flag is not set, consider the array sorted
	if [ -n "$_indices" ] && [ "$_sorted_flag" = 0 ]; then
		_indices="$(printf '%s' "$_indices" | sort -nu)$___newline"
		eval "_i_${_arr_name}_sorted_flag=1"
	fi

	if [ -n "$_indices" ]; then
		_h_index="${_indices%"${___newline}"}"
		_h_index="${_h_index##*"${___newline}"}"
		eval "_i_${_arr_name}_h_index"='$_h_index'
	else
		_h_index="-1"; unset "_i_${_arr_name}_h_index"
	fi

}

# declare an indexed array while populating first elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - new array values
declare_i_arr() {
	___me="declare_i_arr"
	[ -z "$*" ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; shift
	check_strings "$_arr_name" || return 1

	do_unset_i_arr "${_arr_name}"

	_index=0; _indices=''
	for ___val in "$@"; do
		eval "_i_${_arr_name}_${_index}"='$_el_set_flag$___val'
		_indices="$_indices$_index$___newline"
		_index=$((_index + 1))
	done
	_index=$((_index - 1))

	[ "$_index" = "-1" ] && _index=''

	eval "
		_i_${_arr_name}_h_index"='$_index'"
		_i_${_arr_name}_indices"='$_indices'"
		_i_${_arr_name}_sorted_flag=1"
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
	check_strings "$_arr_name" || return 1
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
		eval "
			_i_${_arr_name}_h_index"='$_index'"
			_i_${_arr_name}_indices"='$_indices'"
			_i_${_arr_name}_sorted_flag=1"
	fi

	return 0
}

# read lines from input string into an indexed array
# unsets all previous elements of the array if it already exists
# 1 - array name
# 2 - newline-separated string
read_i_arr() {
	___me="read_i_arr"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; ___lines="$2"
	check_strings "$_arr_name" || return 1

	do_unset_i_arr "${_arr_name}"

	_index=0; _indices=''
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

	eval "
		_i_${_arr_name}_h_index"='$_index'"
		_i_${_arr_name}_indices"='$_indices'"
		_i_${_arr_name}_sorted_flag=1"

	return 0
}

# get all values from an indexed array (sorted by index)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
get_i_arr_values() {
	___me="get_i_arr_values"
	[ "$1" = "-s" ] && { _do_sort=1; shift; }
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; _out_var="$2"; ___values=''
	check_strings "$_arr_name" "$_out_var" || return 1

	if [ -n "$_do_sort" ]; then
		__sort_i_arr
		unset _do_sort
		eval "_i_${_arr_name}_indices"='$_indices'
	else
		eval "_indices=\"\$_i_${_arr_name}_indices\""
	fi

	___values="$(
	for _index in $_indices; do
		eval "___val=\"\${_i_${_arr_name}_${_index}#$_el_set_flag}\""
		[ -n "$___val" ] && printf '%s ' "$___val"
	done
	)"

	eval "$_out_var"='${___values% }'

	return 0
}

# get all indices from an indexed array (sorted)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
get_i_arr_indices() {
	___me="get_i_arr_indices"
	[ "$1" = "-s" ] && { _do_sort=1; shift; }
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1" _out_var="$2"
	check_strings "$_arr_name" "$_out_var" || return 1

	if [ -n "$_do_sort" ]; then
		__sort_i_arr
		unset _do_sort
		eval "_i_${_arr_name}_indices"='$_indices'
	else
		eval "_indices=\"\$_i_${_arr_name}_indices\""
	fi

	# shellcheck disable=SC2086
	_indices="$(printf '%s ' $_indices)" # no quotes on purpose

	eval "$_out_var"='${_indices% }'

	return 0
}

# add a new element to an indexed array and set its value
# 1 - array name
# 2 - value
add_i_arr_el() {
	___me="add_i_arr_el"
	_arr_name="$1"; ___new_val="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_strings "$_arr_name" || return 1

	eval "_h_index=\"\$_i_${_arr_name}_h_index\""
	if [ -z "$_h_index" ]; then
		# populates the $_indices and $_h_index variables and sets the 'sorted' flag
		__sort_i_arr
		_index=$((_h_index + 1))
		eval "_i_${_arr_name}_indices"='${_indices}${_index}${___newline}'
	else
		_index=$((_h_index + 1))
		eval "_i_${_arr_name}_indices=\"\${_i_${_arr_name}_indices}${_index}${___newline}\""
	fi

	eval "_i_${_arr_name}_h_index"='$_index'"
		_i_${_arr_name}_${_index}"='$_el_set_flag$___new_val'
	return 0
}

# unset an element of an indexed array
# 1 - array name
# 2 - index
unset_i_arr_el() {
	___me="unset_i_arr_el"
	_arr_name="$1"; _index="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_strings "$_arr_name" || return 1
	check_index || return 1

	eval "___old_val=\"\$_i_${_arr_name}_${_index}\"
		_h_index=\"\$_i_${_arr_name}_h_index\"
		_sorted_flag=\"\$_i_${_arr_name}_sorted_flag\""

	if [ -n "$___old_val" ]; then
		unset "_i_${_arr_name}_${_index}"

		eval "case \"\$_i_${_arr_name}_indices\" in
			\"${_index}${___newline}\"* )
				_i_${_arr_name}_indices=\"\${_i_${_arr_name}_indices#$_index$___newline}\"
			;;
			*\"${___newline}${_index}${___newline}\"* )
				_i_${_arr_name}_indices=\"\${_i_${_arr_name}_indices%$___newline$_index$___newline*}${___newline}\${_i_${_arr_name}_indices#*$___newline$_index$___newline}\"
		esac"

		if [ "$_index" = "$_h_index" ] && [ "$_sorted_flag" = 1 ]; then
			eval "if [ -n \"\$_i_${_arr_name}_indices\" ]; then
				_i_${_arr_name}_h_index=\"\${_i_${_arr_name}_indices%${___newline}}\"
				_i_${_arr_name}_h_index=\"\${_i_${_arr_name}_h_index##*${___newline}}\"
			else
				_i_${_arr_name}_h_index=''
			fi"
		elif [ "$_index" = "$_h_index" ]; then unset "_i_${_arr_name}_h_index"
		fi

	fi

	return 0
}

# get maximum index of an indexed array
# 1 - array name
# 2 - global variable name for output
get_i_arr_max_index() {
	___me="get_i_arr_max_index"
	_arr_name="$1"; _out_var="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_strings "$_arr_name" "$_out_var" || return 1

	eval "_h_index=\"\$_i_${_arr_name}_h_index\""
	if [ -z "$_h_index" ]; then
		# populates the $_indices variable and sets the 'sorted' flag
		__sort_i_arr
		eval "_i_${_arr_name}_indices"='${_indices}'
		if [ -z "$_indices" ]; then
			unset "$_out_var" "_i_${_arr_name}_indices" _indices _h_index _out_var
			no_elements; return 1
		fi
	fi

	eval "_i_${_arr_name}_h_index"='$_h_index' "$_out_var"='$_h_index'

	return 0
}

# get value of the last element in an indexed array
# 1 - array name
# 2 - global variable name for output
get_i_arr_last_val() {
	___me="get_i_arr_last_val"
	_arr_name="$1"; _out_var="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_strings "$_arr_name" "$_out_var" || return 1

	eval "_h_index=\"\$_i_${_arr_name}_h_index\""
	if [ -z "$_h_index" ]; then
		# populates the $_indices and $_h_index variables and sets the 'sorted' flag
		__sort_i_arr
		eval "_i_${_arr_name}_indices"='${_indices}'
		if [ -z "$_indices" ]; then
			unset "$_out_var" "_i_${_arr_name}_indices" _h_index
			no_elements; return 1
		fi
	fi

	eval "_i_${_arr_name}_h_index"='$_h_index'"
		$_out_var=\"\${_i_${_arr_name}_${_h_index}#$_el_set_flag}\""

	return 0
}

# get the element count of an indexed array
# 1 - array name
# 2 - global variable name for output
get_i_arr_el_cnt() {
	___me="get_i_arr_el_cnt"
	_arr_name="$1"; _out_var="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_strings "$_arr_name" "$_out_var" || return 1

	eval "_indices=\"\$_i_${_arr_name}_indices\""

	i=0
	for _ind in $_indices; do i=$((i+1)); done

	eval "$_out_var"='$i'

	return 0
}

# set an element in an indexed array
# 1 - array name
# 2 - index
# 3 - value (if no value, unsets the element)
set_i_arr_el() {
	___me="set_i_arr_el"
	_arr_name="$1"; _index="$2"; ___new_val="$3"
	if [ $# -lt 2 ] || [ $# -gt 3 ]; then  wrongargs "$@"; return 1; fi
	check_strings "$_arr_name" || return 1
	check_index || return 1

	eval "___old_val=\"\$_i_${_arr_name}_${_index}\"
		_i_${_arr_name}_${_index}"='$_el_set_flag$___new_val'
	if [ -z "$___old_val" ]; then
		eval "
			_i_${_arr_name}_indices=\"\${_i_${_arr_name}_indices}${_index}${___newline}\"
			_h_index=\"\$_i_${_arr_name}_h_index\""
		if [ -n "$_h_index" ] && [ "$_index" -gt  "$_h_index" ]; then
			eval "_i_${_arr_name}_h_index"='$_index'
		else
			eval "_i_${_arr_name}_sorted_flag=0"
		fi
	fi

	return 0
}

# get a value from an indexed array
# output is set as a value of a global variable
# 1 - array name
# 2 - index
# 3 - global variable name for output
get_i_arr_val() {
	___me="get_i_arr_val"
	[ $# != 3 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; _index="$2"; _out_var="$3"
	check_strings "$_arr_name" "$_out_var" || return 1
	check_index || return 1

	eval "$_out_var=\"\${_i_${_arr_name}_${_index}#$_el_set_flag}\""
}


# unsets all variables used to store an associative array
# 1 - array name
unset_a_arr() {
	___me="get_a_arr_val"
	[ $# != 1 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"
	check_strings "$_arr_name" || return 1

	do_unset_a_arr "${_arr_name}"
}

# backend function
# unsets all variables of an associative array
# 1 - array name
do_unset_a_arr() {
	eval "___keys=\"\$_a_${1}___keys\""

	for ___key in $___keys; do
		unset "_a_${1}_${___key}"
	done
	unset "_a_${1}___keys" "_a_${1}_sorted_flag"
}

# wrapper function for __sort_a_arr, intended as a user interface
# 1 - array name
sort_a_arr() {
	___me="sort_a_arr"
	[ $# != 1 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"
	check_strings "$_arr_name" || return 1
	__sort_a_arr
	return 0
}

# backend function
# sorts keys of an associative array
# assigns the resulting keys to $___keys
# updates the '$_a_${_arr_name}____keys' variable
# sets the 'sorted' flag
__sort_a_arr() {
	eval "___keys=\"\$_a_${_arr_name}___keys\"
		_sorted_flag=\"\$_a_${_arr_name}_sorted_flag\""
	# if $_sorted_flag is not set, consider the array unsorted
	if [ -n "$___keys" ] && [ "$_sorted_flag" != 1 ]; then
		___keys="$(printf '%s' "$___keys" | sort -u)$___newline"
		eval "_a_${_arr_name}_sorted_flag=1"
		eval "_a_${_arr_name}___keys"='$___keys'
	fi
}

# declare an associative array while populating elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - 'key=value' pairs
declare_a_arr() {
	___me="declare_a_arr"
	[ -z "$*" ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; shift
	check_strings "$_arr_name" || return 1

	do_unset_a_arr "${_arr_name}"

	___keys=''
	if [ -n "$*" ]; then
		for ___pair in "$@"; do
			check_pair || return 1
			___key="${___pair%%=*}"
			___val="$_el_set_flag${___pair#*=}"
			check_strings "$___key" || return 1
			eval "_a_${_arr_name}_${___key}"='$___val'
			___keys="$___keys$___key$___newline"
		done
	fi

	eval "_a_${_arr_name}___keys"='$___keys'
	return 0
}

# get all values from an associative array (alphabetically sorted by key)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
get_a_arr_values() {
	___me="get_a_arr_values"
	[ "$1" = "-s" ] && { _do_sort=1; shift; }
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; _out_var="$2"
	check_strings "$_arr_name" "$_out_var" || return 1
	if [ -n "$_do_sort" ]; then
		__sort_a_arr
		unset _do_sort
	else
		eval "___keys=\"\$_a_${_arr_name}___keys\""
	fi

	___values="$(
		for ___key in $___keys; do
			eval "___val=\"\${_a_${_arr_name}_${___key}#$_el_set_flag}\""
			[ -n "$___val" ] && printf '%s ' "$___val"
		done
	)"

	eval "$_out_var"='${___values% }'
	return 0
}

# get all keys from an associative array (alphabetically sorted)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
get_a_arr_keys() {
	___me="get_a_arr_keys"
	[ "$1" = "-s" ] && { _do_sort=1; shift; }
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; _out_var="$2"
	check_strings "$_arr_name" "$_out_var" || return 1

	if [ -n "$_do_sort" ]; then
		__sort_a_arr
		unset _do_sort
		# shellcheck disable=SC2086
		___keys="$(printf '%s ' $___keys)" # no extra quotes on purpose
	else
		eval "___keys=\"\$(printf '%s ' \$_a_${_arr_name}___keys)\""
	fi
	# shellcheck disable=SC2086
	eval "$_out_var"='${___keys% }'

	return 0
}

# get the element count of an associative array
# 1 - array name
# 2 - global variable name for output
get_a_arr_el_cnt() {
	___me="get_a_arr_el_cnt"
	_arr_name="$1"; _out_var="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_strings "$_arr_name" "$_out_var" || return 1

	eval "___keys=\"\$_a_${_arr_name}___keys\""

	i=0
	for ___key in $___keys; do i=$((i+1)); done

	eval "$_out_var"='$i'

	return 0
}

# set an element in an associative array
# if value is an empty string, assings empty string to the key
# 1 - array name
# 2 - 'key=value' pair
set_a_arr_el() {
	___me="set_a_arr_el"
	_arr_name="$1"; ___pair="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_pair || return 1
	___key="${___pair%%=*}"
	___new_val="${___pair#*=}"
	check_strings "$_arr_name" "$___key" || return 1

	eval "___old_val=\"\$_a_${_arr_name}_${___key}\"
		_a_${_arr_name}_${___key}"='${_el_set_flag}${___new_val}'
	if [ -z "$___old_val" ]; then
		eval "_a_${_arr_name}_sorted_flag=0
		_a_${_arr_name}___keys=\"\${_a_${_arr_name}___keys}${___key}${___newline}\""
	fi
	return 0
}

# unset an element in an associative array
# 1 - array name
# 2 - key
unset_a_arr_el() {
	___me="unset_a_arr_el"
	_arr_name="$1"; ___key="$2"
	[ $# != 2 ] && { wrongargs "$@"; return 1; }
	check_strings "$_arr_name" "$___key" || return 1

	if eval "[ -n \"\$_a_${_arr_name}_${___key}\" ]"; then
		unset "_a_${_arr_name}_${___key}"
		eval "case \"\$_a_${_arr_name}___keys\" in
			\"${___key}${___newline}\"* ) _a_${_arr_name}___keys=\"\${_a_${_arr_name}___keys#$___key$___newline}\" ;;
			*\"${___newline}${___key}${___newline}\"* )
				_a_${_arr_name}___keys=\"\${_a_${_arr_name}___keys%$___newline$___key$___newline*}${___newline}\${_a_${_arr_name}___keys#*$___newline$___key$___newline}\"
		esac"
	fi

	return 0
}

# get a value from an emulated associative array
# output is set as a value of a global variable
# 1 - array name
# 2 - key
# 3 - global variable name for output
get_a_arr_val() {
	___me="get_a_arr_val"
	[ $# != 3 ] && { wrongargs "$@"; return 1; }
	_arr_name="$1"; ___key="$2"; _out_var="$3"
	check_strings "$_arr_name" "$___key" "$_out_var" || return 1

	eval "___val=\"\$_a_${_arr_name}_${___key}\""
	# shellcheck disable=SC2031
	eval "$_out_var"='${___val#"${_el_set_flag}"}'
}

## Backend functions

check_strings() {
	case "$1$2$3" in *[!A-Za-z0-9_]* )
		case "$_arr_name" in *[!A-Za-z0-9_]* ) echo "$___me: Error: invalid array name '$_arr_name'." >&2; return 1; esac
		case "$_out_var" in *[!A-Za-z0-9_]* ) echo "$___me: Error: invalid output variable name '$_out_var'." >&2; return 1; esac
		case "$___key" in *[!A-Za-z0-9_]* ) echo "$___me: Error: invalid key '$___key'." >&2; return 1; esac;
	esac
}

no_elements() { echo "$___me: Error: array '$_arr_name' has no elements." >&2; }
check_index() {	case "$_index" in *[!0-9]* ) echo "$___me: Error: '$_index' is not a nonnegative integer." >&2; return 1; esac; }
check_pair() { case "$___pair" in *=* ) ;; * ) echo "$___me: Error: '$___pair' is not a 'key=value' pair." >&2; return 1; esac; }
wrongargs() { echo "$___me: Error: '$*': wrong number of arguments '$#'." >&2; }

## Constants

export LC_ALL=C
___newline="
"
_el_set_flag="$(printf '\35')"
