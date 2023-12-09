#!/bin/sh

# posix-arrays.sh

# emulates arrays in POSIX shell

# each array element is stored in a variable named in the format '___[x]_[arr_name]_[key/index]'
# where [x] is either 'a' for associative array or 'i' for indexed array

# keys/indices are stored in a variable named in the format '___[x]_[arr_name]_keys' or '___[x]_[arr_name]_indices'
# array flags are stored in variables (true if variable is set): $___[x]_[arr_name]_sorted, $___[x]_[arr_name]_verified
# for indexed arrays, $_i_[arr_name]_h_index variable holds the highest index in the array if it's known


# declare an indexed array while populating first elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - array values
declare_i_arr() {
	___me="declare_i_arr"
	[ $# -lt 1 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1"; shift
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	eval "_indices=\"\$_i_${_arr_name}_indices\""

	for _index in $_indices; do
		unset "_i_${_arr_name}_${_index}"
	done
	unset "_i_${_arr_name}_indices"
	unset _indices "_i_${_arr_name}_h_index"

	_index=0
	if [ -n "$*" ]; then
		for ___val in "$@"; do
			eval "_i_${_arr_name}_${_index}=\"$___val\""
			_indices="$_indices$_index$___newline"
			_index=$((_index + 1))
		done
	fi

	eval "_i_${_arr_name}_h_index=\"$((_index - 1))\";
		_i_${_arr_name}_indices=\"$_indices\";
		_i_${_arr_name}___sorted=1;
		_i_${_arr_name}___verified=1"
	unset ___val _index _indices
	return 0
}

# read lines from input string into an indexed array
# unsets all previous elements of the array if it already exists
# 1 - array name
# 2 - newline-separated string
# no additional arguments are allowed
read_i_arr() {
	___me="read_i_arr"
	[ $# -ne 2 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1"; ___lines="$2"
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	eval "_indices=\"\$_i_${_arr_name}_indices\""

	for _index in $_indices; do
		unset "_i_${_arr_name}_${_index}"
	done
	unset "_i_${_arr_name}_indices" _indices

	_index=0
    IFS_OLD="$IFS"
    IFS="$___newline"
	for ___line in $___lines; do
		eval "_i_${_arr_name}_${_index}=\"$___line\""
		_indices="$_indices$_index$___newline"
		_index=$((_index + 1))
	done
    IFS="$IFS_OLD"

	eval "_i_${_arr_name}_h_index=\"$((_index - 1))\";
		_i_${_arr_name}_indices=\"$_indices\";
		_i_${_arr_name}___sorted=1;
		_i_${_arr_name}___verified=1"

	unset ___line ___lines _index _indices _input_file
	return 0
}

# unsets all variables used to store the array
unset_i_arr() {
	___me="unset_i_arr"
	[ $# -ne 1 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1"
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	eval "_indices=\"\$_i_${_arr_name}_indices\""

	for _index in $_indices; do
		unset "_i_${_arr_name}_${_index}"
	done
	unset _indices _index "_i_${_arr_name}_h_index" "_i_${_arr_name}_indices"
}

# get all values from an indexed array (sorted by index)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_values() {
	___me="get_i_arr_values"
	[ $# -ne 2 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1"; _out_var="$2"; ___values=''
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	# populates $_indices variable and sets the 'sorted' and 'verified' flags
	sort_and_verify_i_arr
	eval "_i_${_arr_name}_indices=\"$_indices\""

	[ -n "$_indices" ] && ___values="$(
	for _index in $_indices; do
		eval "printf '%s ' \"\$_i_${_arr_name}_${_index}\""
	done
	)"

	eval "$_out_var=\"${___values% }\""

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
	[ $# -ne 2 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1" _out_var_name="$2"
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	# populates $_indices variable and sets the 'sorted' and 'verified' flags
	sort_and_verify_i_arr
	eval "_i_${_arr_name}_indices=\"$_indices\""

	# shellcheck disable=SC2086
	_indices="$(printf '%s ' $_indices)" # no quotes on purpose

	eval "$_out_var_name=\"${_indices% }\""

	unset _indices _out_var_name
	return 0
}

# sorts and verifies indices of indexed array
# assigns the resulting indices to $_indices
# sets the 'sorted' and 'verified' flags
# caller should update the '$_i_${_arr_name}_indices' variable externally
sort_and_verify_i_arr() {
	eval "_indices=\"\$_i_${_arr_name}_indices\";
		___sorted=\"\$_i_${_arr_name}___sorted\";
		___verified=\"\$_i_${_arr_name}___verified\""

	if [ -n "$_indices" ]; then
		if [ -z "$___sorted" ] && [ -z "$___verified" ]; then
			_indices="$(
				for _index in $_indices; do
					eval "___val=\"\$_i_${_arr_name}_${_index}\""
					[ -n "$___val" ] && printf '%s\n' "$_index"
				done | sort -nu
			)"
			[ -n "$_indices" ] && _indices="${_indices#"$___newline"}$___newline"
			eval "_i_${_arr_name}___sorted=1; _i_${_arr_name}___verified=1"
		elif [ -n "$___sorted" ] && [ -z "$___verified" ]; then
			_indices="$(
				for _index in $_indices; do
					eval "___val=\"\$_i_${_arr_name}_${_index}\""
					[ -n "$___val" ] && printf '%s\n' "$_index"
				done
			)"
			[ -n "$_indices" ] && _indices="${_indices#"$___newline"}$___newline"
			eval "_i_${_arr_name}___verified=1"
		elif [ -z "$___sorted" ] && [ -n "$___verified" ]; then
			_indices="$(printf '%s\n' "$_indices" | sort -nu)$___newline"
			eval "_i_${_arr_name}___sorted=1"
		fi
	fi
	unset ___val ___sorted ___verified _index
}

# add a new element to an indexed array and set its value
# 1 - array name
# 2 - value
# no additional arguments are allowed
add_i_arr_el() {
	___me="add_i_arr_el"
	_arr_name="$1"; ___new_val="$2"
	[ $# -ne 2 ] && { eval "$_wrongargs"; return 1; }
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	eval "_h_index=\"\$_i_${_arr_name}_h_index\""
	if [ -z "$_h_index" ]; then
		# populates $_indices variable and sets the 'sorted' and 'verified' flags
		sort_and_verify_i_arr
		[ -n "$_indices" ] && {
			_h_index="${_indices%"$___newline"}"
			_h_index="${_h_index##*"$___newline"}"
		} || _h_index="-1"

		_index=$((_h_index + 1))
		eval "_i_${_arr_name}_indices=\"${_indices}${_index}${___newline}\""
	else
		_index=$((_h_index + 1))
		eval "_i_${_arr_name}_indices=\"\${_i_${_arr_name}_indices}${_index}${___newline}\""
	fi

	eval "_i_${_arr_name}_h_index=\"$_index\";
		_i_${_arr_name}_${_index}=\"$___new_val\""

	unset ___new_val _indices _index _h_index
	return 0
}

# get maximum index of an indexed array
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_i_arr_max_index() {
	___me="get_i_arr_max_index"
	_arr_name="$1"; _out_var_name="$2"
	[ $# -ne 2 ] && { eval "$_wrongargs"; return 1; }
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	eval "_h_index=\"\$_i_${_arr_name}_h_index\""
	if [ -z "$_h_index" ]; then
		# populates the $_indices variable and sets the 'sorted' and 'verified' flags
		sort_and_verify_i_arr
		[ -n "$_indices" ] && {
			_h_index="${_indices%"$___newline"}"
			_h_index="${_h_index##*"$___newline"}"
		} || _h_index="-1"
	else
		eval "_indices=\"\$_i_${_arr_name}_indices\""
	fi

	if [ "$_h_index" != "-1" ]; then
		eval "_i_${_arr_name}_h_index=\"$_h_index\";
			$_out_var_name=\"$_h_index\"
			_i_${_arr_name}_indices=\"${_indices}\""
	else
		unset "$_out_var_name" "_i_${_arr_name}_indices" _indices _h_index _out_var_name
		eval "$_badindex"; return 1
	fi

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
	[ $# -ne 2 ] && { eval "$_wrongargs"; return 1; }
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	eval "_h_index=\"\$_i_${_arr_name}_h_index\""
	if [ -z "$_h_index" ]; then
		# populates the $_indices variable and sets the 'sorted' and 'verified' flags
		sort_and_verify_i_arr
		if [ -n "$_indices" ]; then
			_h_index="${_indices%"$___newline"}"
			_h_index="${_h_index##*"$___newline"}"
		else _h_index="-1"
		fi
	else
		eval "_indices=\"\$_i_${_arr_name}_indices\""
	fi

	if [ "$_h_index" != "-1" ]; then
		eval "_i_${_arr_name}_h_index=\"$_h_index\";
			$_out_var_name=\"\$_i_${_arr_name}_${_h_index}\";
			_i_${_arr_name}_indices=\"${_indices}\""
	else
		unset "$_out_var_name" "_i_${_arr_name}_indices" _indices _h_index _out_var_name
		eval "$_badindex"; return 1
	fi

	unset _indices _h_index _out_var_name
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
	if [ $# -lt 2 ] || [ $# -gt 3 ]; then eval "$_wrongargs"; return 1; fi
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac
	case "$_index" in *[!0-9]*) eval "$_wrongindex"; return 1 ; esac

	eval "___old_val=\"\$_i_${_arr_name}_${_index}\""
	if [ -z "$___old_val" ] && [ -n "$___new_val" ]; then
		eval "_i_${_arr_name}_indices=\"\${_i_${_arr_name}_indices}${_index}${___newline}\";
			_i_${_arr_name}_${_index}=\"$___new_val\";
			_h_index=\"\$_i_${_arr_name}_h_index\""
		if [ -n "$_h_index" ] && [ "$_index" -gt  "$_h_index" ]; then
			eval "_i_${_arr_name}_h_index=$_index"
		else
			unset "_i_${_arr_name}___sorted"
		fi
	elif [ -n "$___old_val" ] && [ -z "$___new_val" ]; then
		unset "_i_${_arr_name}___verified" "_i_${_arr_name}_${_index}"
		eval "_h_index=\"\$_i_${_arr_name}_h_index\""
		[ "$_index" =  "$_h_index" ] && unset "_i_${_arr_name}_h_index"
	elif [ -n "$___old_val" ] && [ -n "$___new_val" ]; then
		eval "_i_${_arr_name}_${_index}=\"$___new_val\""
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
	[ $# -ne 3 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1"; _index="$2"; _out_var_name="$3"
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac
	case "$_index" in *[!0-9]*) eval "$_wrongindex"; return 1; esac

	eval "$_out_var_name=\"\$_i_${_arr_name}_${_index}\""
	unset _index _out_var_name
}



# declare an associative array while populating elements
# resets all previous elements of the array if it already exists
# 1 - array name
# all other args - 'key=value' pairs
declare_a_arr() {
	___me="declare_a_arr"
	[ $# -lt 1 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1"; shift
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	eval "___keys=\"\$_a_${_arr_name}___keys\""

	for ___key in $___keys; do
		unset "_a_${_arr_name}_${___key}"
	done
	unset ___keys "_a_${_arr_name}___keys"

	if [ -n "$*" ]; then
		for ___pair in "$@"; do
			case "$___pair" in *=*) ;; *) eval "$_wrongpair"; return 1 ;; esac
			___key="${___pair%%=*}"
			___val="$___delim${___pair#*=}"
			case "$___key" in *[!A-Za-z0-9_]*) eval "$_wrongkey"; return 1; esac
			eval "_a_${_arr_name}_${___key}=\"$___val\""
			___keys="$___keys$___key$___newline"
		done
	fi

	[ -n "$___keys" ] && ___keys="$(printf '%s\n' "$___keys" | sort -u)$___newline"
	eval "_a_${_arr_name}___keys=\"$___keys\"; _a_${_arr_name}___sorted=1; _a_${_arr_name}___verified=1"
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
	[ $# -ne 2 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1"; _out_var_name="$2"; ___values=''
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	sort_and_verify_a_arr
	___values="$(
		for ___key in $___keys; do
		eval "IFS=\"$___delim\"; printf '%s '\$_a_${_arr_name}_${___key}"
		done
	)"

	eval "$_out_var_name=\"${___values% }\""
	unset ___keys ___key ___values
	return 0
}

# sorts and verifies keys of an associative array
# assigns the resulting keys to $___keys
# updates the '$_a_${_arr_name}____keys' variable
# sets the 'sorted' and 'verified' flags
sort_and_verify_a_arr() {
	eval "___keys=\"\$_a_${_arr_name}___keys\";
		___sorted=\"\$_a_${_arr_name}___sorted\";
		___verified=\"\$_a_${_arr_name}___verified\""
	if [ -n "$___keys" ]; then
		if [ -z "$___sorted" ] && [ -z "$___verified" ]; then
			___keys="$(
				for ___key in $___keys; do
					eval "___val=\"\$_a_${_arr_name}_${___key}\""
					[ -n "$___val" ] && printf '%s\n' "$___key"
				done | sort -u
			)"
			[ -n "$___keys" ] && ___keys="${___keys#"$___newline"}$___newline"
			eval "_a_${_arr_name}___sorted=1; _a_${_arr_name}___verified=1"
		elif [ -n "$___sorted" ] && [ -z "$___verified" ]; then
			___keys="$(
				for ___key in $___keys; do
					eval "___val=\"\$_a_${_arr_name}_${___key}\""
					[ -n "$___val" ] && printf '%s\n' "$___key"
				done
			)"
			[ -n "$___keys" ] && ___keys="${___keys#"$___newline"}$___newline"
			eval "_a_${_arr_name}___verified=1"
		elif [ -z "$___sorted" ] && [ -n "$___verified" ]; then
			___keys="$(printf '%s\n' "$___keys" | sort -u)$___newline"
			eval "_a_${_arr_name}___sorted=1"
		fi
		eval "_a_${_arr_name}___keys=\"$___keys\""
	fi
	unset ___val ___sorted ___verified ___key
}

# get all keys from an associative array (alphabetically sorted)
# whitespace-delimited output is set as a value of a global variable
# 1 - array name
# 2 - global variable name for output
# no additional arguments are allowed
get_a_arr_keys() {
	___me="get_a_arr_keys"
	[ $# -ne 2 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1"; _out_var=$2
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	sort_and_verify_a_arr
	# shellcheck disable=SC2086
	___keys="$(printf '%s ' $___keys)"
	eval "$_out_var=\"${___keys% }\""

	unset ___keys _out_var
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
	[ $# -ne 2 ] && { eval "$_wrongargs"; return 1; }
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac
	case "$___pair" in *=*) ;; *) eval "$_wrongpair"; return 1 ; esac
	___key="${___pair%%=*}"
	___new_val="${___pair#*=}"
	case "$___key" in *[!A-Za-z0-9_]*) eval "$_wrongkey"; return 1; esac

	eval "___old_val=\"\$_a_${_arr_name}_${___key}\""
	[ -z "$___old_val" ] && unset "_a_${_arr_name}___sorted"

	eval "_a_${_arr_name}___keys=\"\${_a_${_arr_name}___keys}${___key}${___newline}\""
	eval "_a_${_arr_name}_${___key}=\"${___delim}${___new_val}\""

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
	[ $# -ne 2 ] && { eval "$_wrongargs"; return 1; }
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac
	case "$___key" in *[!A-Za-z0-9_]*) eval "$_wrongkey"; return 1; esac

	eval "___old_val=\"\$_a_${_arr_name}_${___key}\""

	[ -n "$___old_val" ] && unset "_a_${_arr_name}_${___key}" "_a_${_arr_name}___verified"

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
	[ $# -ne 3 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1"; ___key="$2"; _out_var="$3"
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac
	case "$___key" in *[!A-Za-z0-9_]*) eval "$_wrongkey"; return 1; esac

	eval "___val=\"\$_a_${_arr_name}_${___key}\""
	# shellcheck disable=SC2031
	eval "$_out_var=\"${___val#"${___delim}"}\""
	unset ___key _out_var
}

# unsets all variables used to store the array
unset_a_arr() {
	___me="get_a_arr_val"
	[ $# -ne 1 ] && { eval "$_wrongargs"; return 1; }
	_arr_name="$1"
	case "$_arr_name" in *[!A-Za-z0-9_]*) eval "$_wrongname"; return 1; esac

	eval "___keys=\"\$_a_${_arr_name}___keys\""
	for ___key in $___keys; do
		unset "_a_${_arr_name}_${___key}"
	done
	unset "_a_${_arr_name}___keys" "_a_${_arr_name}___sorted" "_a_${_arr_name}___verified"
	unset ___keys ___key
}


___newline="
"
_wrongargs="echo \"\$___me: Error: '\$*': \$# - wrong number of arguments.\" >&2"
_wrongname="echo \"\$___me: Error: invalid array name '\$_arr_name'.\" >&2"
_wrongkey="echo \"\$___me: Error: invalid key '\$___key'.\" >&2"
_wrongindex="echo \"\$___me: Error: no index specified or '\$_index' is not a nonnegative integer.\" >&2"
_wrongpair="echo \"\$___me: Error: '\$___pair' is not a 'key=value' pair.\" >&2"
_badindex="echo \"\$___me: Error: array '\$_arr_name' has no elements.\" >&2"
___delim="$(printf '\35')"
