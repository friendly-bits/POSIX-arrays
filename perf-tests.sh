#!/bin/sh

## Initial setup

export LC_ALL=C
me=$(basename "$0")

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck disable=SC2015

source_file="${1:-posix-arrays.sh}"
# shellcheck disable=SC1090
. "$script_dir/$source_file" || { echo "$me: Error: Can't source '$script_dir/$source_file'." >&2; exit 1; }


## Test function

warmup() {
	if [ "$arr_type" = "i" ]; then
		for i in $elements; do
			set_i_arr_el test_arr "$i" "$test_str"
		done
	else
		for i in $elements; do
			set_a_arr_el test_arr "abcdefghijklmn$i=$test_str"
		done
	fi
}

test_add() {
	if [ "$arr_type" = "i" ]; then
		for j in $elements; do
			add_i_arr_el test_arr "$test_str"
		done
	fi
}
 
test_set() {
	if [ "$arr_type" = "i" ]; then
		for i in $elements; do
			set_i_arr_el test_arr "$i" "$test_str"
		done
	else
		for i in $elements; do
			set_a_arr_el test_arr "abcdefghijklmn$i=$test_str"
		done
	fi
}
 
test_unset() {
	if [ "$arr_type" = "i" ]; then
		for i in $elements; do
			unset_${arr_type}_arr_el test_arr "$i"
		done
	else
		for i in $elements; do
			unset_${arr_type}_arr_el test_arr "abcdefghijklmn$i"
		done
	fi
}

test_get() {
	if [ "$arr_type" = "i" ]; then
		for i in $elements; do
			get_${arr_type}_arr_val test_arr "$i" testvar
			# printf '%s\n' "$testvar" >/dev/null
			# printf '%s\n' "${test_arr[$i]}" >/dev/null
		done
 	else
		for i in $elements; do
			get_${arr_type}_arr_val test_arr "abcdefghijklmn$i" testvar
			# printf '%s\n' "$testvar" >/dev/null
			# printf '%s\n' "${test_arr[$i]}" >/dev/null
		done
	fi
}

test_mixed() {
	if [ "$arr_type" = "i" ]; then
		for j in $elements; do
			if [ $((j % 10)) = 0 ]; then get_i_arr_indices test_arr testvar; fi
			set_i_arr_el test_arr "$((j*2))" "$test_str"
			add_i_arr_el test_arr "$test_str"
			unset_i_arr_el test_arr "$((j+1))"
		done
		# set_${arr_type}_arr_val test_arr "$i" "$test_str"
		# add_${arr_type}_arr_el test_arr "$test_str"
	else
		for j in $elements; do
			set_a_arr_el test_arr "$((j*2))=$test_str"
			set_a_arr_el test_arr "$((j*2 -2))="
			get_a_arr_keys test_arr testvar
		done
		# set_${arr_type}_arr_val test_arr "$i" "$test_str"
		# add_${arr_type}_arr_el test_arr "$test_str"
	fi
}

test_get_arr_el_cnt() {
	# shellcheck disable=SC2086
	get_${arr_type}_arr_el_cnt test_arr rescnt
}

test_get_keys() {
	if [ "$arr_type" = "i" ]; then
		get_i_arr_indices test_arr reskeys
	else
		get_a_arr_keys test_arr reskeys
	fi
}

test_get_arr_values() {
	get_${arr_type}_arr_values test_arr testvar
}

test_init() {
	init_i_arr test_arr $((l+1))
}


## Auxiliary functions

get_uptime() {
	# shellcheck disable=SC2034
	read -r uptime_raw dummy < /proc/uptime
	curr_time="${uptime_raw%.*}${uptime_raw#*.}0"
}

get_date() {
	curr_time="$(date +%s%N)"
	curr_time="${curr_time%??????}"
}

measure_time() {
	exec_command="$1"; description="${1#test_}"; shift
	__args="$*"
	$time_func
	start_time="$curr_time"
	# shellcheck disable=SC2086
	$exec_command $__args
	$time_func
	echo "$description time: $(( curr_time - start_time )) ms"
	unset curr_time
}


## Main

# Determine the way to get time
testdate="$(date +%N)"
if [ -z "$testdate" ]; then
	time_func="get_uptime"
	start_time=''
	measure_time echo 1>/dev/null
	case "$start_time" in *[!0-9]* ) echo "Error: cannot determine a way to measure time on this sytem."; exit 1; esac
	echo "Note: time measurement precision is limited to 10 ms on this sytem."
elif [ ${#testdate} -eq 9 ]; then
	time_func="get_date"
else
	echo "Error: Unexpected result from 'date +%N" command; exit 1
fi



arr_type="i" # i for indexed array, a for associative array
test_str="a b; 'c%d^e#fh2uyuIJKlk/*-+UnapTg#@! %% " # string used to assign to elements

# Warmup
f=1 # first element
l=1 # last element
elements=$(seq $f $l)
warmup

# echo "Indices after warmup:"
# echo "'$_i_test_arr_indices'"

# Test variables
f=1 # first element
l=1000 # last element
elements=$(seq $f $l)

# Execute tests

echo "Running tests from element $f to element $l."

measure_time test_set

measure_time test_get

measure_time test_get_keys

measure_time test_get_arr_values

measure_time test_get_arr_el_cnt

measure_time test_unset

measure_time test_mixed
 
[ "$arr_type" = i ] && {
	measure_time test_add
} 

measure_time test_get_arr_el_cnt

[ "$arr_type" = i ] && {
	measure_time test_init
	measure_time test_set
}


# echo "Resulting raw keys:"
# if [ "$arr_type" = "i" ]; then
# 	printf '%s\n' "'$_i_test_arr_indices'"
# else
# 	printf '%s\n' "'$_a_test_arr_keys'"
# fi


# echo "Resulting reported keys:"
# if [ "$arr_type" = "i" ]; then
# 	get_i_arr_indices test_arr reskeys
# else
# 	get_a_arr_keys test_arr reskeys
# fi
# printf '%s\n' "'$reskeys'"

# get_${arr_type}_arr_values test_arr resulting_values
# echo "Resulting values:"
# echo "'$resulting_values'"
