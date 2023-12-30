#!/bin/sh

# posix-arrays-indexed.sh

# emulates *indexed* arrays in POSIX shell

# each array element is stored in a variable named in the format '_i_[arr_name]_[index]'

# indices are stored in a variable named in the format '_i_[arr_name]_indices'
# array 'sorted' flag (1=true, 0=false) is stored in variable: $_i_[arr_name]_sorted_flag
# the $_i_[arr_name]_h_index variable holds the highest index in the array if it's known


# unsets all variables used to store an indexed array
# 1 - array name
unset_i_arr() {
	___me="unset_i_arr"
	case "$#" in 1 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1"
	check_strings "$_arr_name" || return 1

	do_unset_i_arr "${_arr_name}"
}

# backend function
# unsets all variables of an indexed array
# 1 - array name
do_unset_i_arr() {
	eval "_indices=\"\$_i_${1}_indices\$_i_${1}_indices_b\""

	for _index in $_indices; do
		unset "_i_${1}_${_index}"
	done
	unset "_i_${1}_indices" "_i_${1}_indices_b" "_i_${1}_h_index" "_i_${_arr_name}_sorted_flag"
}

# wrapper function for __sort_i_arr, intended as a user interface
# 1 - array name
sort_i_arr() {
	___me="sort_i_arr"
	case "$#" in 1 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1"
	check_strings "$_arr_name" || return 1
	__sort_i_arr
	return 0
}

# backend function
# sorts indices of indexed array
# sets the 'sorted' flag
__sort_i_arr() {
	eval "_sorted_flag=\"\$_i_${_arr_name}_sorted_flag\"
		_h_index=\"\${_i_${_arr_name}_h_index}\""

	case "$_sorted_flag" in
	1) eval "_indices=\"\$_i_${_arr_name}_indices\"" ;;
	'' ) _h_index="-1" ;;
	* ) eval "_indices=\"\$(printf '%s' \"\$_i_${_arr_name}_indices\$_i_${_arr_name}_indices_b\" | sort -n)\"
			_i_${_arr_name}_indices=\"\$_indices\"
			_i_${_arr_name}_indices_b=''
			_i_${_arr_name}_sorted_flag=1"
	esac
}

# backend function
# finds the max index and assigns to variables '_h_index' and '_i_${arr_name}_h_index'
_get_h_index() {
	case "$_h_index" in '' )
		_h_index="${_indices##*"${___newline}"}"
		eval "_i_${_arr_name}_h_index"='$_h_index'
	esac
}

# declare an indexed array while populating first elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - new array values
declare_i_arr() {
	___me="declare_i_arr"
	case "$*" in '' ) wrongargs "$@"; return 1; esac
	_arr_name="$1"; shift
	check_strings "$_arr_name" || return 1

	do_unset_i_arr "${_arr_name}"

	_index=0; _indices=''
	for ___val in "$@"; do
		eval "_i_${_arr_name}_${_index}"='$_el_set_flag$___val'
		_indices="$_indices$___newline$_index"
		_index=$((_index + 1))
	done
	_index=$((_index - 1))

	case "$_index" in
		"-1" ) ;;
		* ) eval "_i_${_arr_name}_h_index"='$_index'"
				_i_${_arr_name}_indices"='$_indices'"
				_i_${_arr_name}_sorted_flag=1"
	esac
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
	case $((3 - $#)) in 0|1 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1"; _el_num="$2"; _val="$3"
	check_strings "$_arr_name" || return 1
	_index="$_el_num"; check_index || return 1
	_h_index=$((_el_num-1))

	do_unset_i_arr "${_arr_name}"

	case "$_h_index" in
		"-1" ) ;;
		* )
			_index=0; _indices=''
			while [ $_index -le "$_h_index" ]; do
				eval "_i_${_arr_name}_${_index}"='$_el_set_flag$_val'
				_indices="$_indices$___newline$_index"
				_index=$((_index + 1))
			done
			_index=$((_index - 1))
			eval "
				_i_${_arr_name}_h_index"='$_index'"
				_i_${_arr_name}_indices"='$_indices'"
				_i_${_arr_name}_sorted_flag=1"
	esac

	return 0
}

# read lines from input string into an indexed array
# unsets all previous elements of the array if it already exists
# 1 - array name
# 2 - newline-separated string
read_i_arr() {
	___me="read_i_arr"
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1"; ___lines="$2"
	check_strings "$_arr_name" || return 1

	do_unset_i_arr "${_arr_name}"

	_index=0; _indices=''
	IFS_OLD="$IFS"
	IFS="$___newline"
	for ___line in $___lines; do
		eval "_i_${_arr_name}_${_index}"='$_el_set_flag$___line'
		_indices="$_indices$___newline$_index"
		_index=$((_index + 1))
	done
	IFS="$IFS_OLD"

	_index=$((_index - 1))
	case "$_index" in
		"-1" ) ;;
		* ) eval "
				_i_${_arr_name}_h_index"='$_index'"
				_i_${_arr_name}_indices"='$_indices'"
				_i_${_arr_name}_sorted_flag=1"
	esac
	return 0
}

# get all values from an indexed array
# whitespace-delimited output is set as a value of a global variable
# (0 - optional: '-s' : sort the array by index and output sorted values)
# 1 - array name
# 2 - global variable name for output
get_i_arr_values() {
	___me="get_i_arr_values"
	[ "$1" = "-s" ] && { _do_sort=1; shift; }
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1"; _out_var="$2"; ___values=''
	check_strings "$_arr_name" "$_out_var" || return 1

	case "$_do_sort" in '' );;
		* ) __sort_i_arr
			unset _do_sort
	esac
	eval "_indices=\"\${_i_${_arr_name}_indices}\${_i_${_arr_name}_indices_b}\""

	___values="$(
		for _index in $_indices; do
			eval "___val=\"\${_i_${_arr_name}_${_index}#$_el_set_flag}\""
			[ -n "$___val" ] && printf '%s ' "$___val"
		done
	)"

	eval "$_out_var"='${___values% }'

	return 0
}

# get all indices from an indexed array
# whitespace-delimited output is set as a value of a global variable
# (0 - optional: '-s' : sort the array and output sorted indices)
# 1 - array name
# 2 - global variable name for output
get_i_arr_indices() {
	___me="get_i_arr_indices"
	[ "$1" = "-s" ] && { _do_sort=1; shift; }
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1" _out_var="$2"
	check_strings "$_arr_name" "$_out_var" || return 1

	case "$_do_sort" in '' );;
		* ) __sort_i_arr
			unset _do_sort
	esac
	eval "_indices=\"\${_i_${_arr_name}_indices}\${_i_${_arr_name}_indices_b}\""

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
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	check_strings "$_arr_name" || return 1

	eval "_h_index=\"\$_i_${_arr_name}_h_index\""
	case "$_h_index" in '' ) __sort_i_arr; _get_h_index; esac
	case "$_h_index" in "-1" ) eval "_i_${_arr_name}_sorted_flag=1"; esac

	_index=$((_h_index + 1))
	eval "_i_${_arr_name}_indices=\"\${_i_${_arr_name}_indices}${___newline}${_index}\"
		_i_${_arr_name}_h_index"='$_index'"
		_i_${_arr_name}_${_index}"='$_el_set_flag$___new_val'

	return 0
}

# unset an element of an indexed array
# 1 - array name
# 2 - index
unset_i_arr_el() {
	_rm_mid_index() {
		eval "___last_ind=\"\${${1}##*$___newline}\"
				___first_ind=\"\${${1}#$___newline}\""
		# shellcheck disable=SC2154
		case $((___last_ind + ${___first_ind%%"$___newline"*} < 2*_index)) in
			1 ) eval "_i_${_arr_name}${1}=\"\${${1}%$___newline$_index$___newline*}$___newline\${${1}##*$___newline$_index$___newline}\"" ;;
			0 ) eval "_i_${_arr_name}${1}=\"\${${1}%%$___newline$_index$___newline*}$___newline\${${1}#*$___newline$_index$___newline}\""
		esac
	}

	___me="unset_i_arr_el"
	_arr_name="$1"; _index="$2"
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	check_strings "$_arr_name" || return 1
	check_index || return 1

	eval "_sorted_flag=\"\$_i_${_arr_name}_sorted_flag\"
		_h_index=\"\$_i_${_arr_name}_h_index\"
		___old_val=\"\$_i_${_arr_name}_${_index}\""
	# shellcheck disable=SC2154
	case "$___old_val" in '' ) ;; * )
		unset "_i_${_arr_name}_${_index}"
		case "$_sorted_flag" in
			1) 	eval "_indices=\"\$_i_${_arr_name}_indices\""
				case "${_indices#"$___newline"}" in
					"$_index" ) unset "_i_${_arr_name}_indices"
								unset "_i_${_arr_name}_h_index" "_i_${_arr_name}_sorted_flag" ;;
					"$_index$___newline"* ) eval "_i_${_arr_name}_indices=\"\${_indices#$___newline$_index}\"" ;;
					*"$___newline$_index" ) eval "_i_${_arr_name}_indices=\"\${_indices%$___newline$_index}\"
												_i_${_arr_name}_h_index=\"\${_i_${_arr_name}_indices##*${___newline}}\"" ;;
					*"$___newline$_index$___newline"* ) _rm_mid_index "_indices" ;;
					'' ) unset "_i_${_arr_name}_h_index" "_i_${_arr_name}_sorted_flag"
				esac
				;;
			0) 	eval "_indices=\"\$_i_${_arr_name}_indices\"; _indices_b=\"\$_i_${_arr_name}_indices_b\""
				_no_b_ind=''
				# shellcheck disable=SC2154
				case "${_indices_b#"$___newline"}" in
					"$_index$___newline"* ) eval "_i_${_arr_name}_indices_b=\"\${_indices_b#$___newline$_index}\"" ;;
					*"$___newline$_index" ) eval "_i_${_arr_name}_indices_b=\"\${_indices_b%$___newline$_index}\"" ;;
					*"$___newline$_index$___newline"* ) _rm_mid_index "_indices_b" ;;
					"$_index" ) unset "_i_${_arr_name}_indices_b"; _no_b_ind=1 ;;
					'' ) _no_b_ind=1
				esac
				case "${_indices#"$___newline"}" in
					"$_index" ) unset "_i_${_arr_name}_indices"
						case "$_no_b_ind" in 1) unset "_i_${_arr_name}_h_index" "_i_${_arr_name}_sorted_flag"; return 0; esac ;;
					"$_index$___newline"* ) eval "_i_${_arr_name}_indices=\"\${_indices#$___newline$_index}\"" ;;
					*"$___newline$_index" ) eval "_i_${_arr_name}_indices=\"\${_indices%$___newline$_index}\"" ;;
					*"$___newline$_index$___newline"* ) _rm_mid_index "_indices" ;;
					'' ) case "$_no_b_ind" in 1) unset "_i_${_arr_name}_h_index" "_i_${_arr_name}_sorted_flag"; return 0; esac
				esac
				case "$_index" in "$_h_index" ) unset "_i_${_arr_name}_h_index"; esac
		esac
	esac

	return 0
}

# get maximum index of an indexed array
# 1 - array name
# 2 - global variable name for output
get_i_arr_max_index() {
	___me="get_i_arr_max_index"
	_arr_name="$1"; _out_var="$2"
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	check_strings "$_arr_name" "$_out_var" || return 1

	eval "_sorted_flag=\"\$_i_${_arr_name}_sorted_flag\"
			_h_index=\"\$_i_${_arr_name}_h_index\""
	case "$_h_index" in
		'' )
			case "$_sorted_flag" in
				'' ) unset "$_out_var" "_i_${_arr_name}_indices" _h_index _out_var
					no_elements; return 1 ;;
				* ) __sort_i_arr; _get_h_index; eval "$_out_var"='$_h_index'
			esac ;;
		* ) eval "$_out_var"='$_h_index'
	esac
	return 0
}

# get value of the last element in an indexed array
# 1 - array name
# 2 - global variable name for output
get_i_arr_last_val() {
	___me="get_i_arr_last_val"
	_arr_name="$1"; _out_var="$2"
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	check_strings "$_arr_name" "$_out_var" || return 1

	eval "_sorted_flag=\"\$_i_${_arr_name}_sorted_flag\"
			_h_index=\"\$_i_${_arr_name}_h_index\""
	case "$_h_index" in
		'' )
			case "$_sorted_flag" in
				'' ) unset "$_out_var" "_i_${_arr_name}_indices" _h_index _out_var
					no_elements; return 1 ;;
				* ) __sort_i_arr; _get_h_index; eval "$_out_var=\"\${_i_${_arr_name}_${_h_index}#$_el_set_flag}\""
			esac ;;
		* ) eval "$_out_var=\"\${_i_${_arr_name}_${_h_index}#$_el_set_flag}\""
	esac
	return 0
}

# get the element count of an indexed array
# 1 - array name
# 2 - global variable name for output
get_i_arr_el_cnt() {
	___me="get_i_arr_el_cnt"
	_arr_name="$1"; _out_var="$2"
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	check_strings "$_arr_name" "$_out_var" || return 1

	eval "_indices=\"\$_i_${_arr_name}_indices\${_i_${_arr_name}_indices_b}\""

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
	case $((3 - $#)) in 0|1 ) ;; * ) wrongargs "$@"; return 1; esac
	check_strings "$_arr_name" || return 1
	check_index || return 1

	eval "___old_val=\"\$_i_${_arr_name}_${_index}\"
			_i_${_arr_name}_${_index}"='$_el_set_flag$___new_val'
	case "$___old_val" in '' )
		eval "_h_index=\"\$_i_${_arr_name}_h_index\"
			_sorted_flag=\"\$_i_${_arr_name}_sorted_flag\""
		___entry="$___newline$_index"
		case "$_sorted_flag" in '' ) # no existing elements in the array
			eval "_i_${_arr_name}_sorted_flag=1
				_i_${_arr_name}_h_index=\"$_index\"
				_i_${_arr_name}_indices=\"$___entry\""
			return 0
		esac
		case "$_h_index" in '' ) ;; * )
			case $((_index - _h_index)) in 0|-* ) ;; * )
				case "$_sorted_flag" in
					1 ) _target_list="_indices" ;;
					* ) _target_list="_indices_b"
				esac
				eval "_i_${_arr_name}${_target_list}=\"\${_i_${_arr_name}${_target_list}}$___entry\"
					_i_${_arr_name}_h_index=$_index"
				return 0
			esac
		esac
		eval "_i_${_arr_name}_sorted_flag=0
			_i_${_arr_name}_indices_b=\"\${_i_${_arr_name}_indices_b}$___entry\""
	esac
	return 0
}

# get a value from an indexed array
# output is set as a value of a global variable
# 1 - array name
# 2 - index
# 3 - global variable name for output
get_i_arr_val() {
	___me="get_i_arr_val"
	case "$#" in 3 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1"; _index="$2"; _out_var="$3"
	check_strings "$_arr_name" "$_out_var" || return 1
	check_index || return 1

	eval "$_out_var=\"\${_i_${_arr_name}_${_index}#$_el_set_flag}\""
}


## Backend functions

check_strings() {
	case "$1$2$3" in *[!A-Za-z0-9_]* )
		case "$_arr_name" in *[!A-Za-z0-9_]* ) echo "$___me: Error: invalid array name '$_arr_name'." >&2; return 1; esac
		case "$_out_var" in *[!A-Za-z0-9_]* ) echo "$___me: Error: invalid output variable name '$_out_var'." >&2; return 1; esac
	esac
}

no_elements() { echo "$___me: Error: array '$_arr_name' has no elements." >&2; }
check_index() {	case "$_index" in *[!0-9]* ) echo "$___me: Error: '$_index' is not a nonnegative integer." >&2; return 1; esac; }
wrongargs() { echo "$___me: Error: '$*': wrong number of arguments '$#'." >&2; }

## Constants

export LC_ALL=C
___newline="
"
_el_set_flag="$(printf '\35')"
