#!/bin/sh

export LC_ALL=C
me=$(basename "$0")

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck disable=SC2015

. "$script_dir/emulate-arrays.sh" || { echo "$me: Error: Can't source '$script_dir/emulate-arrays.sh'." >&2; exit 1; }

warmup() {
	for i in $keys; do
		set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
	done
}
 
test_set() {
	for i in $keys; do
		set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
        # test_arr[$i]="a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@!%% "
	done
}
 
test_unset1() {
	for i in $keys; do
		set_${arr_type}_arr_el test_arr "$i" ""
        # test_arr[$i]=""
	done
}
 
test_unset2() {
	for i in $keys; do
		set_${arr_type}_arr_el test_arr "$i" ""
        # test_arr[$i]=""
	done
}
 
test_unset3() {
	for i in $keys; do
		set_${arr_type}_arr_el test_arr "$i" ""
        # test_arr[$i]=""
	done
}
 
test_get() {
	for i in $keys; do
		get_${arr_type}_arr_el test_arr $i >/dev/null
        # printf '%s\n' "${test_arr[$i]}" >/dev/null
	done
    printf '\n'
}

# Warmup
f=1
n=1
arr_type="i"
keys=$(seq $f $n)
warmup

#echo "Indices after warmup:"
#eval "echo \"\$emu_i_test_arr_indices\""

# Test
f=1
n=3000
arr_type="i"

keys=$(seq $f $n)
__start_set=$(date +%s%N)
test_set
__end_set=$(date +%s%N)
 
keys=$(seq $f $n)
__start_get=$(date +%s%N)
test_get
__end_get=$(date +%s%N)
 
#echo
__start_get_all1=$(date +%s%N)
get_${arr_type}_arr_all test_arr >/dev/null
__end_get_all1=$(date +%s%N)

keys=$(seq $((f + (n-f)/4)) $((n-(n-f)/4)) )
__start_unset3=$(date +%s%N)
test_unset3
__end_unset3=$(date +%s%N)

keys=$(seq $f $((f+(n-f)/4 - 1)) )
__start_unset1=$(date +%s%N)
test_unset1
__end_unset1=$(date +%s%N)
 
keys=$(seq $n -1 $((n + 1 - (n-f)/4)) )
__start_unset2=$(date +%s%N)
test_unset2
__end_unset2=$(date +%s%N)
 
__start_get_all2=$(date +%s%N)
resulting_values="$(get_${arr_type}_arr_all test_arr)"
__end_get_all2=$(date +%s%N)
 
 
echo "Total set time: $(( (__end_set - __start_set)/1000000 )) ms"

echo "Total get time: $(( (__end_get - __start_get)/1000000 )) ms"
echo "get all time: $(( (__end_get_all1 - __start_get_all1)/1000000 )) ms"
echo "Total unset1 time: $(( (__end_unset1 - __start_unset1)/1000000 )) ms"
echo "Total unset2 time: $(( (__end_unset2 - __start_unset2)/1000000 )) ms"
echo "Total unset3 time: $(( (__end_unset3 - __start_unset3)/1000000 )) ms"
echo "get all 2 time: $(( (__end_get_all2 - __start_get_all2)/1000000 )) ms"

# echo "Resulting keys:"
# echo "$___emu_i_test_arr_keys"

# echo "Resulting values:"
# echo "'$resulting_values'"
