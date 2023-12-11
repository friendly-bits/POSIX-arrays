#!/bin/sh

export LC_ALL=C
me=$(basename "$0")

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck disable=SC2015

source_file="${1:-posix-arrays.sh}"
# shellcheck disable=SC1090
. "$script_dir/$source_file" || { echo "$me: Error: Can't source '$script_dir/$source_file'." >&2; exit 1; }

warmup() {
	if [ "$arr_type" = "i" ]; then
		for i in $elements; do
			set_i_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		done
	else
		for i in $elements; do
			set_a_arr_el test_arr "abcdefghijklmn$i=a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		done
	fi
}

test_add() {
	if [ "$arr_type" = "i" ]; then
		for j in $elements; do
			add_i_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		done
	fi
}
 
test_set() {
	if [ "$arr_type" = "i" ]; then
		for i in $elements; do
			set_i_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		done
	else
		for i in $elements; do
			set_a_arr_el test_arr "abcdefghijklmn$i=a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
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
  printf '\n'
}

test_mixed() {
	if [ "$arr_type" = "i" ]; then
		for j in $elements; do
			if [ $((j % 10)) = 0 ]; then get_i_arr_indices test_arr testvar; fi
			set_i_arr_el test_arr "$((j*2))" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
			add_i_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
			unset_i_arr_el test_arr "$((j+1))"
		done
		# set_${arr_type}_arr_val test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
	else
		for j in $elements; do
			set_a_arr_el test_arr "$((j*2))=a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
			set_a_arr_el test_arr "$((j*2 -2))="
			get_a_arr_keys test_arr testvar
		done
		# set_${arr_type}_arr_val test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
	fi
}
 
# Check the 'date' command output
testdate="$(date +%N)"
if [ -z "$testdate" ]; then
	timeunits="s"; timefactor="1"
	echo "Note: time measurement precision is limited to seconds on this sytem."
elif [ ${#testdate} -eq 9 ]; then
	timeunits="ms"; timefactor="1000000"
else
	echo "Error: Unexpected result from 'date +%N" command; exit 1
fi



arr_type="i"

# Warmup
f=1
n=1
elements=$(seq $f $n)
warmup

# echo "Indices after warmup:"
# echo "'$_i_test_arr_indices'"

# Test
f=1
n=1000

elements=$(seq $f $n)
__start_set=$(date +%s%N)
test_set
__end_set=$(date +%s%N)

elements=$(seq $f $n)
__start_cnt1=$(date +%s%N)
get_${arr_type}_arr_el_cnt test_arr rescnt
__end_cnt1=$(date +%s%N)

__start_get_keys=$(date +%s%N)
if [ "$arr_type" = "i" ]; then
	get_i_arr_indices test_arr reskeys
else
	get_a_arr_keys test_arr reskeys
fi
__end_get_keys=$(date +%s%N)

elements=$(seq $f $n)
__start_get=$(date +%s%N)
test_get
__end_get=$(date +%s%N)
 
__start_get_all=$(date +%s%N)
get_${arr_type}_arr_values test_arr testvar
#printf '%s\n' "$testvar" >/dev/null
__end_get_all=$(date +%s%N)

elements=$(seq $f $n )
__start_unset=$(date +%s%N)
test_unset
__end_unset=$(date +%s%N)

elements=$(seq $f $n)
__start_mixed=$(date +%s%N)
test_mixed
__end_mixed=$(date +%s%N)
 
[ "$arr_type" = i ] && {
	elements=$(seq $f $n)
	__start_add=$(date +%s%N)
	test_add
	__end_add=$(date +%s%N)
} 

__start_cnt2=$(date +%s%N)
get_${arr_type}_arr_el_cnt test_arr rescnt
__end_cnt2=$(date +%s%N)

echo "set time: $(( (__end_set - __start_set)/timefactor )) $timeunits"
[ "$arr_type" = i ] && echo "add time: $(( (__end_add - __start_add)/timefactor )) $timeunits"
echo "get time: $(( (__end_get - __start_get)/timefactor )) $timeunits"
echo "get all vals time: $(( (__end_get_all - __start_get_all)/timefactor )) $timeunits"
echo "get keys time: $(( (__end_get_keys - __start_get_keys)/timefactor )) $timeunits"
echo "unset time: $(( (__end_unset - __start_unset)/timefactor )) $timeunits"
echo "mixed time: $(( (__end_mixed - __start_mixed)/timefactor )) $timeunits"
echo "el count time 1: $(( (__end_cnt1 - __start_cnt1)/timefactor )) $timeunits"
echo "el count time 2: $(( (__end_cnt2 - __start_cnt2)/timefactor )) $timeunits"

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
