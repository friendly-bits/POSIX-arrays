#!/bin/sh
# shellcheck disable=SC2154,SC2086

# Copyright: friendly bits
# github.com/friendly-bits

# posix-arrays-associative.sh

# emulates *associative* arrays in POSIX shell

# each array element is stored in a variable named in the format '_a_[arr_name]_[key]'

# keys are stored in a variable named in the format '_a_[arr_name]_keys'
# buffered keys are stored in a variable named in the format  '_a_[arr_name]_keys_b'
# array 'sorted' flag (1=true, 0=false) is stored in variable: $_a_[arr_name]_sorted_flag
# the 'sorted' flag is also used as an indicator of whether the array has any elements (for performance reasons)


# unsets all variables used to store an associative array
# 1 - array name
unset_a_arr() {
	___me="unset_a_arr"
	case $# in 1) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1"
	_check_vars _arr_name || return 1

	_do_unset_a_arr "${_arr_name}"
	unset "_a_${_arr_name}_sorted_flag"
}

# backend function
# unsets all variables of an associative array
# 1 - array name
_do_unset_a_arr() {
	eval "___keys=\"\${_a_${1}___keys:-}\${_a_${1}___keys_b:-}\""

	for ___key in $___keys; do
		unset "_a_${1}_${___key}"
	done
	unset "_a_${1}___keys" "_a_${1}___keys_b"
}

# wrapper function for __sort_a_arr, intended as a user interface
# 1 - array name
sort_a_arr() {
	___me="sort_a_arr"
	case $# in 1) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1"
	_check_vars _arr_name || return 1
	__sort_a_arr
	:
}

# backend function
# sorts keys of an associative array
# assigns the resulting keys to $___keys
# updates the '$_a_${_arr_name}____keys' variable
# sets the 'sorted' flag
__sort_a_arr() {
	eval "___sorted_flag=\"\${_a_${_arr_name}_sorted_flag:-}\""
	case "$___sorted_flag" in
		1) eval "___keys=\"\${_a_${_arr_name}___keys:-}\"" ;;
		*) eval "___keys=\"\$(printf %s \"\${_a_${_arr_name}___keys:-}\${_a_${_arr_name}___keys_b:-}\" | sort -u)\"
			_a_${_arr_name}___keys=\"\$___keys\"
			_a_${_arr_name}___keys_b=''
			_a_${_arr_name}_sorted_flag=1"
	esac
}

# declare an associative array while populating elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - 'key=value' pairs
declare_a_arr() {
	___me="declare_a_arr"
	case $# in 0) wrongargs "$@"; return 1; esac
	_arr_name="$1"; shift
	_check_vars _arr_name || return 1

	_do_unset_a_arr "${_arr_name}"

	___keys=''
	case "$*" in *?* )
		for ___pair in "$@"; do
			check_pair || return 1
			___key="${___pair%%=*}"
			___val="$_el_set_flag${___pair#*=}"
			_check_vars ___key || return 1
			eval "_a_${_arr_name}_${___key}"='$___val'
			___keys="$___keys$___nl$___key"
		done
	esac

	eval "_a_${_arr_name}___keys=\"$___keys\"; _a_${_arr_name}_sorted_flag=0"

	:
}

# get all values from an associative array (alphabetically sorted by key)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
get_a_arr_values() {
	___me="get_a_arr_values"
	[ "$1" = "-s" ] && { _do_sort=1; shift; }
	case $# in 2) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1"; _out_var="$2"; ___keys=''
	_check_vars _arr_name _out_var || return 1

	case "$_do_sort" in
		'') eval "___keys=\"\${_a_${_arr_name}___keys:-}\${_a_${_arr_name}___keys_b:-}\"" ;;
		*) __sort_a_arr
			unset _do_sort
	esac

	___values=''
	case "$___keys" in *?* )
		___values="$(
			for ___key in $___keys; do
				eval "___val=\"\${_a_${_arr_name}_${___key}:-}\""
				___val="${___val#$_el_set_flag}"
				case "$___val" in *?* ) printf '%s ' "$___val"; esac
			done
		)"
	esac

	eval "$_out_var"='${___values% }'
	:
}

# get all keys from an associative array (alphabetically sorted)"
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
get_a_arr_keys() {
	___me="get_a_arr_keys"
	[ "$1" = "-s" ] && { _do_sort=1; shift; }
	case $# in 2) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1"; _out_var="$2"; ___keys=''
	_check_vars _arr_name _out_var || return 1

	case "$_do_sort" in
		'') eval "___keys=\"\$(printf '%s ' \${_a_${_arr_name}___keys:-}\${_a_${_arr_name}___keys_b:-})\"" ;;
		*) __sort_a_arr
			unset _do_sort
			___keys="$(printf '%s ' $___keys)" # no extra quotes on purpose
	esac
	eval "$_out_var"='${___keys% }'

	:
}

# get the element count of an associative array
# 1 - array name
# 2 - global variable name for output
get_a_arr_el_cnt() {
	___me="get_a_arr_el_cnt"
	case $# in 2) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1"; _out_var="$2"
	_check_vars _arr_name _out_var || return 1

	eval "___keys=\"\${_a_${_arr_name}___keys:-}\${_a_${_arr_name}___keys_b:-}\""

	i=0
	for ___key in $___keys; do i=$((i+1)); done

	eval "$_out_var"='$i'

	:
}

# set an element in an associative array
# if value is an empty string, assings empty string to the key
# 1 - array name
# 2 - 'key=value' pair
set_a_arr_el() {
	___me="set_a_arr_el"
	case $# in 2) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1"; ___pair="$2"
	check_pair || return 1
	___key="${___pair%%=*}"
	___new_val="${___pair#*=}"
	_check_vars _arr_name ___key || return 1

	eval "___old_val=\"\${_a_${_arr_name}_${___key}:-}\"
			_sorted_flag=\"\${_a_${_arr_name}_sorted_flag:-}\"
			_a_${_arr_name}_${___key}"='${_el_set_flag}${___new_val}'

	case "$___old_val" in '')
		case "$_sorted_flag" in
			'') eval "_a_${_arr_name}_sorted_flag=1
				_a_${_arr_name}___keys=\"${___nl}${___key}\""
			;;
			*) eval "_a_${_arr_name}_sorted_flag=0
				_a_${_arr_name}___keys_b=\"\${_a_${_arr_name}___keys_b:-}${___nl}${___key}\""
		esac
	esac

	:
}

# unset an element in an associative array
# 1 - array name
# 2 - key
unset_a_arr_el() {
	_rm_mid_key() {
		eval "_a_${_arr_name}${1}=''
			for ___key_tmp in \$${1}"';'" do
				case $___key in
					\"\$___key_tmp\" ) ;;
					*) _a_${_arr_name}${1}=\"\${_a_${_arr_name}${1}}$___nl\$___key_tmp\"
				esac
			done"
	}

	___me="unset_a_arr_el"
	case $# in 2) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1"; ___key="$2"
	_check_vars _arr_name ___key || return 1

	eval "_sorted_flag=\"\${_a_${_arr_name}_sorted_flag:-}\"
		___old_val=\"\${_a_${_arr_name}_${___key}:-}\""
	case "$___old_val" in *?* )
		unset "_a_${_arr_name}_${___key}"
		case "$_sorted_flag" in
			1) 	eval "___keys=\"\${_a_${_arr_name}___keys:-}\""
				_no_b_keys=1 ;;
			0) 	eval "___keys=\"\${_a_${_arr_name}___keys:-}\"; ___keys_b=\"\${_a_${_arr_name}___keys_b:-}\""
				_no_b_keys=''
				case "${___keys_b#"$___nl"}" in
					"$___key$___nl"* ) eval "_a_${_arr_name}___keys_b=\"\${___keys_b#$___nl$___key}\"" ;;
					*"$___nl$___key" ) eval "_a_${_arr_name}___keys_b=\"\${___keys_b%$___nl$___key}\"" ;;
					*"$___nl$___key$___nl"* ) _rm_mid_key "___keys_b" ;;
					"$___key" ) unset "_a_${_arr_name}___keys_b"; _no_b_keys=1 ;;
					'') _no_b_keys=1
				esac
				;;
			'') return 0
		esac
		case "${___keys#"$___nl"}" in
			"$___key" ) unset "_a_${_arr_name}___keys"
						case "$_no_b_keys" in 1) unset "_a_${_arr_name}_sorted_flag"; esac ;;
			"$___key$___nl"* ) eval "_a_${_arr_name}___keys=\"\${___keys#$___nl$___key}\"" ;;
			*"$___nl$___key" ) eval "_a_${_arr_name}___keys=\"\${___keys%$___nl$___key}\"" ;;
			*"$___nl$___key$___nl"* ) _rm_mid_key  "___keys" ;;
			'') case "$_no_b_keys" in 1) unset "_a_${_arr_name}_sorted_flag"; esac
		esac
	esac

	:
}

# get a value from an emulated associative array
# output is set as a value of a global variable
# 1 - array name
# 2 - key
# 3 - global variable name for output
get_a_arr_val() {
	___me="get_a_arr_val"
	case $# in 3) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1"; ___key="$2"; _out_var="$3"
	_check_vars _arr_name ___key _out_var || return 1
	eval "___val=\"\${_a_${_arr_name}_${___key}:-}\""
	eval "$_out_var"='${___val#"${_el_set_flag}"}'
}


## Backend functions

_check_vars() {
	for ___var in "$@"; do
		eval "_var_val=\"\$$___var\""
		case "$_var_val" in ''|*[!A-Za-z0-9_]* )
			case "$___var" in
				___key) _var_desc="key" ;;
				_arr_name) _var_desc="array name" ;;
				_out_var) _var_desc="output variable name"
			esac
			printf '%s\n' "$___me: Error: invalid $_var_desc '$_var_val'." >&2
			return 1
		esac
	done
}

no_elements() { echo "$___me: Error: array '$_arr_name' has no elements." >&2; }
check_pair() { case "$___pair" in *=* ) ;; *) echo "$___me: Error: '$___pair' is not a 'key=value' pair." >&2; return 1; esac; }
wrongargs() { echo "$___me: Error: '$*': wrong number of arguments '$#'." >&2; }

## Constants

set -f
export LC_ALL=C
___nl='
'
: "${_el_set_flag:="$(printf '\35')"}"
