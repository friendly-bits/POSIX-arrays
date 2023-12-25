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
	case "$#" in 1 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1"
	check_strings "$_arr_name" || return 1

	do_unset_i_arr "${_arr_name}"
}

# backend function
# unsets all variables of an indexed array
# 1 - array name
do_unset_i_arr() {
	eval "_indices=\"\$_i_${1}_indices\$_i_${1}_indices_buf\""

	for _index in $_indices; do
		unset "_i_${1}_${_index}"
	done
	unset "_i_${1}_indices" "_i_${1}_indices_buf" "_i_${1}_h_index" "_i_${_arr_name}_sorted_flag"
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
	* ) eval "_indices=\"\$(printf '%s' \"\$_i_${_arr_name}_indices\$_i_${_arr_name}_indices_buf\" | sort -n)\"
			_i_${_arr_name}_indices=\"\$_indices\"
			_i_${_arr_name}_indices_buf=''
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
	eval "_indices=\"\${_i_${_arr_name}_indices}\${_i_${_arr_name}_indices_buf}\""

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
	eval "_indices=\"\${_i_${_arr_name}_indices}\${_i_${_arr_name}_indices_buf}\""

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
	_rm_1st_index() { eval "_i_${_arr_name}${1}=\"\${${1}#$___newline$_index}\""; }
	_rm_last_index() { eval "_i_${_arr_name}${1}=\"\${${1}%$___newline$_index}\""; }
	_rm_mid_index() {
		eval "_i_${_arr_name}${1}=''
			for _ind_tmp in \$${1}"';'" do
				case \"$_index\" in \"\$_ind_tmp\" );;
					*) _i_${_arr_name}${1}=\"\${_i_${_arr_name}${1}}$___newline\$_ind_tmp\"; esac
			done"
	}

	___me="unset_i_arr_el"
	_arr_name="$1"; _index="$2"
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	check_strings "$_arr_name" || return 1
	check_index || return 1

	eval "_sorted_flag=\"\$_i_${_arr_name}_sorted_flag\"
		_h_index=\"\$_i_${_arr_name}_h_index\"
		___old_val=\"\$_i_${_arr_name}_${_index}\""
	case "$___old_val" in '' ) ;; * )
		unset "_i_${_arr_name}_${_index}"
		case "$_sorted_flag" in
			1) 	eval "_indices=\"\$_i_${_arr_name}_indices\""
				_no_buf_ind='1';;
			0) 	eval "_indices=\"\$_i_${_arr_name}_indices\"; _indices_buf=\"\$_i_${_arr_name}_indices_buf\""
				_no_buf_ind=''
				case "${_indices_buf#$___newline}" in
					"$_index" ) _rm_1st_index "_indices_buf"; _no_buf_ind=1 ;;
					"$_index$___newline"* ) _rm_1st_index "_indices_buf" ;;
					*"$___newline$_index" ) _rm_last_index "_indices_buf" ;;
					*"${___newline}$_index$___newline"* ) _rm_mid_index "_indices_buf" ;;
					'' ) _no_buf_ind=1
				esac
			;;
			'') return 0
		esac
		case "${_indices#$___newline}" in
			"$_index" ) _rm_1st_index "_indices"
				case "$_no_buf_ind" in '');; *) unset "_i_${_arr_name}_h_index" "_i_${_arr_name}_sorted_flag"; return 0; esac ;;
			"$_index$___newline"* ) _rm_1st_index "_indices" ;;
			*"$___newline$_index" ) _rm_last_index "_indices" ;;
			*"${___newline}$_index$___newline"* ) _rm_mid_index "_indices" ;;
			'' ) case "$_no_buf_ind" in '');; *) unset "_i_${_arr_name}_h_index" "_i_${_arr_name}_sorted_flag"; return 0; esac
		esac

		if [ "$_index" = "$_h_index" ] && [ "$_sorted_flag" = 1 ]; then
			eval "_i_${_arr_name}_h_index=\"\${_i_${_arr_name}_indices##*${___newline}}\""
		elif [ "$_index" = "$_h_index" ]; then
			unset "_i_${_arr_name}_h_index"
		fi
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

	eval "_indices=\"\$_i_${_arr_name}_indices\${_i_${_arr_name}_indices_buf}\""

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
					* ) _target_list="_indices_buf"
				esac
				eval "_i_${_arr_name}${_target_list}=\"\${_i_${_arr_name}${_target_list}}$___entry\"
					_i_${_arr_name}_h_index=$_index"
				return 0
			esac
		esac
		eval "_i_${_arr_name}_sorted_flag=0
			_i_${_arr_name}_indices_buf=\"\${_i_${_arr_name}_indices_buf}$___entry\""
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


# unsets all variables used to store an associative array
# 1 - array name
unset_a_arr() {
	___me="get_a_arr_val"
	case "$#" in 1 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1"
	check_strings "$_arr_name" || return 1

	_do_unset_a_arr "${_arr_name}"
	unset "_a_${_arr_name}_sorted_flag"
}

# backend function
# unsets all variables of an associative array
# 1 - array name
_do_unset_a_arr() {
	eval "___keys=\"\$_a_${1}___keys\$_a_${1}___keys_buf\""

	for ___key in $___keys; do
		unset "_a_${1}_${___key}"
	done
	unset "_a_${1}___keys" "_a_${1}___keys_buf"
}

# wrapper function for __sort_a_arr, intended as a user interface
# 1 - array name
sort_a_arr() {
	___me="sort_a_arr"
	case "$#" in 1 ) ;; * ) wrongargs "$@"; return 1; esac
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
	eval "___sorted_flag=\"\$_a_${_arr_name}_sorted_flag\""
	case "$___sorted_flag" in
		1 ) eval "___keys=\"\$_a_${_arr_name}___keys\"" ;;
		* )
		eval "___keys=\"\$(printf '%s' \"\$_a_${_arr_name}___keys\$_a_${_arr_name}___keys_buf\" | sort -u)\"
			_a_${_arr_name}___keys=\"\$___keys\"
			_a_${_arr_name}___keys_buf=''
			_a_${_arr_name}_sorted_flag=1"
	esac
}

# declare an associative array while populating elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - 'key=value' pairs
declare_a_arr() {
	___me="declare_a_arr"
	case "$*" in '' ) wrongargs "$@"; return 1; esac
	_arr_name="$1"; shift
	check_strings "$_arr_name" || return 1

	_do_unset_a_arr "${_arr_name}"

	___keys=''
	case "$*" in '' ) ;; * )
		for ___pair in "$@"; do
			check_pair || return 1
			___key="${___pair%%=*}"
			___val="$_el_set_flag${___pair#*=}"
			check_strings "$___key" || return 1 # todo: revert assignments
			eval "_a_${_arr_name}_${___key}"='$___val'
			___keys="$___keys$___newline$___key"
		done
	esac

	eval "_a_${_arr_name}___keys=\"$___keys\"; _a_${_arr_name}_sorted_flag=0"

	return 0
}

# get all values from an associative array (alphabetically sorted by key)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
get_a_arr_values() {
	___me="get_a_arr_values"
	[ "$1" = "-s" ] && { _do_sort=1; shift; }
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1"; _out_var="$2"; ___keys=''
	check_strings "$_arr_name" "$_out_var" || return 1

	case "$_do_sort" in
		'' ) eval "___keys=\"\$_a_${_arr_name}___keys\$_a_${_arr_name}___keys_buf\"" ;;
		* )
			__sort_a_arr
			unset _do_sort
	esac

	___values=''
	case "$___keys" in '' ) ;; * )
		___values=$(
			for ___key in $___keys; do
				eval "___val=\"\${_a_${_arr_name}_${___key}#$_el_set_flag}\""
				case "$___val" in '' ) ;; *) printf '%s ' "$___val"; esac
			done
		)
	esac

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
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	_arr_name="$1"; _out_var="$2"; ___keys=''
	check_strings "$_arr_name" "$_out_var" || return 1

	case "$_do_sort" in
		'' ) eval "___keys=\"\$(printf '%s ' \$_a_${_arr_name}___keys\$_a_${_arr_name}___keys_buf)\"" ;;
		* )
			__sort_a_arr
			unset _do_sort
			# shellcheck disable=SC2086
			___keys="$(printf '%s ' $___keys)" # no extra quotes on purpose
	esac
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
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	check_strings "$_arr_name" "$_out_var" || return 1

	eval "___keys=\"\$_a_${_arr_name}___keys\$_a_${_arr_name}___keys_buf\""

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
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	check_pair || return 1
	___key="${___pair%%=*}"
	___new_val="${___pair#*=}"
	check_strings "$_arr_name" "$___key" || return 1

	eval "___old_val=\"\$_a_${_arr_name}_${___key}\"
			_sorted_flag=\"\$_a_${_arr_name}_sorted_flag\"
			_a_${_arr_name}_${___key}"='${_el_set_flag}${___new_val}'

	case "$___old_val" in '' )
		case "$_sorted_flag" in
			'' ) eval "_a_${_arr_name}_sorted_flag=1
				_a_${_arr_name}___keys=\"${___newline}${___key}\""
			;;
			* ) eval "_a_${_arr_name}_sorted_flag=0
				_a_${_arr_name}___keys_buf=\"\${_a_${_arr_name}___keys_buf}${___newline}${___key}\""
		esac
	esac

	return 0
}

# unset an element in an associative array
# 1 - array name
# 2 - key
unset_a_arr_el() {
	_rm_1st_key() { eval "_a_${_arr_name}${1}=\"\${${1}#$___newline$___key}\""; }
	_rm_last_key() { eval "_a_${_arr_name}${1}=\"\${${1}%$___newline$___key}\""; }
	_rm_mid_key() {
		eval "_a_${_arr_name}${1}=\"\$(
			for ___key_tmp in \$${1}"';'" do
				case \"$___key\" in \"\$___key_tmp\" ) ;; * ) printf '\n%s' \"\$___key_tmp\"; esac
			done
		)\""
	}

	___me="unset_a_arr_el"
	_arr_name="$1"; ___key="$2"
	case "$#" in 2 ) ;; * ) wrongargs "$@"; return 1; esac
	check_strings "$_arr_name" "$___key" || return 1

	eval "_sorted_flag=\"\$_a_${_arr_name}_sorted_flag\"
		___old_val=\"\$_a_${_arr_name}_${___key}\""
	case "$___old_val" in '' ) ;; * )
		unset "_a_${_arr_name}_${___key}"
		case "$_sorted_flag" in
			1) 	eval "___keys=\"\$_a_${_arr_name}___keys\""
				_no_buf_keys=1 ;;
			0) 	eval "___keys=\"\$_a_${_arr_name}___keys\"; ___keys_buf=\"\$_a_${_arr_name}___keys_buf\""
				_no_buf_keys=''
				case "${___keys_buf#$___newline}" in
					*"$___newline$___key" ) _rm_last_key "___keys_buf" ;;
					"$___key" ) _rm_1st_key "___keys_buf"; _no_buf_keys=1 ;;
					'' ) _no_buf_keys=1 ;;
					"$___key$___newline"* ) _rm_1st_key "___keys_buf" ;;
					*"${___newline}$___key$___newline"* ) _rm_mid_key "___keys_buf"
				esac
			;;
			'') return 0
		esac
		case "${___keys#$___newline}" in
			*"$___newline$___key" ) _rm_last_key "___keys" ;;
			"$___key$___newline"* ) _rm_1st_key "___keys" ;;
			*"${___newline}$___key$___newline"* ) _rm_mid_key  "___keys";;
			"$___key" ) _rm_1st_key "___keys"; case "$_no_buf_keys" in '');; *) unset "_a_${_arr_name}_sorted_flag"; return 0; esac ;;
			'' ) case "$_no_buf_keys" in '');; *) unset "_a_${_arr_name}_sorted_flag"; return 0; esac
		esac
	esac

	return 0
}



# get a value from an emulated associative array
# output is set as a value of a global variable
# 1 - array name
# 2 - key
# 3 - global variable name for output
get_a_arr_val() {
	___me="get_a_arr_val"
	case "$#" in 3 ) ;; * ) wrongargs "$@"; return 1; esac
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
