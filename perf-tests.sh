#!/bin/sh

export LC_ALL=C
me=$(basename "$0")

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck disable=SC2015

. "$script_dir/emulate-arrays.sh" || { echo "$me: Error: Can't source '$script_dir/emulate-arrays.sh'." >&2; exit 1; }

warmup() {
	if [ "$arr_type" = "i" ]; then
		for i in $elements; do
			set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		done
	else
		for i in $elements; do
			set_${arr_type}_arr_el test_arr "abcdefghijklmn$i=a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		done
	fi
}
 
test_set() {
	if [ "$arr_type" = "i" ]; then
		for i in $elements; do
			set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		done
	else
		for i in $elements; do
			set_${arr_type}_arr_el test_arr "abcdefghijklmn$i=a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		done
	fi
}
 
test_unset() {
	if [ "$arr_type" = "i" ]; then
		for i in $elements; do
			set_${arr_type}_arr_el test_arr "$i" ""
		done
	else
		for i in $elements; do
			set_${arr_type}_arr_el test_arr "abcdefghijklmn$i="
		done
	fi
}
 
test_get() {
	if [ "$arr_type" = "i" ]; then
		for i in $elements; do
			get_${arr_type}_arr_el test_arr $i >/dev/null
			# printf '%s\n' "${test_arr[$i]}" >/dev/null
		done
 	else
		for i in $elements; do
			get_${arr_type}_arr_el test_arr "abcdefghijklmn$i" >/dev/null
			# printf '%s\n' "${test_arr[$i]}" >/dev/null
		done
	fi
  printf '\n'
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

# Warmup
f=1
n=1
arr_type="a"
elements=$(seq $f $n)
warmup

#echo "Indices after warmup:"
#eval "echo \"\$emu_i_test_arr_indices\""

# Test
f=1
n=1000
arr_type="a"

elements=$(seq $f $n)
__start_set=$(date +%s%N)
test_set
__end_set=$(date +%s%N)
 
elements=$(seq $f $n)
__start_get=$(date +%s%N)
test_get
__end_get=$(date +%s%N)
 
#echo
__start_get_all1=$(date +%s%N)
get_${arr_type}_arr_values test_arr >/dev/null
__end_get_all1=$(date +%s%N)

elements=$(seq $((f + (n-f)/4)) $((n-(n-f)/4)) )
__start_unset3=$(date +%s%N)
test_unset
__end_unset3=$(date +%s%N)

elements=$(seq $f $((f+(n-f)/4 - 1)) )
__start_unset1=$(date +%s%N)
test_unset
__end_unset1=$(date +%s%N)
 
elements=$(seq $n -1 $((n + 1 - (n-f)/4)) )
__start_unset2=$(date +%s%N)
test_unset
__end_unset2=$(date +%s%N)
 
__start_get_all2=$(date +%s%N)
resulting_values="$(get_${arr_type}_arr_values test_arr)"
__end_get_all2=$(date +%s%N)
 

echo "Total set time: $(( (__end_set - __start_set)/timefactor )) $timeunits"

echo "Total get time: $(( (__end_get - __start_get)/timefactor )) $timeunits"
echo "get all time: $(( (__end_get_all1 - __start_get_all1)/timefactor )) $timeunits"
echo "Total unset1 time: $(( (__end_unset1 - __start_unset1)/timefactor )) $timeunits"
echo "Total unset2 time: $(( (__end_unset2 - __start_unset2)/timefactor )) $timeunits"
echo "Total unset3 time: $(( (__end_unset3 - __start_unset3)/timefactor )) $timeunits"
echo "get all 2 time: $(( (__end_get_all2 - __start_get_all2)/timefactor )) $timeunits"

# echo "Resulting keys:"
# eval echo "\$___emu_${arr_type}_test_arr_keys"

echo "Resulting values:"
echo "'$resulting_values'"
