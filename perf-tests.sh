#!/bin/sh

export LC_ALL=C
me=$(basename "$0")

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck disable=SC2015

source_file="${1:-emulate-arrays.sh}"
# shellcheck disable=SC1090
. "$script_dir/$source_file" || { echo "$me: Error: Can't source '$script_dir/$source_file'." >&2; exit 1; }

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
 
test_add() {
	if [ "$arr_type" = "i" ]; then
		for j in $elements; do
			add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
			# set_${arr_type}_arr_el test_arr "$((j+5))" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
			# get_i_arr_values test_arr testvar
		done
		# set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# set_${arr_type}_arr_el test_arr "$i" "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
		# add_${arr_type}_arr_el test_arr "a b;c%d^e#fh152uyuIJKlk/*-+UnapTg#@! %% "
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
			get_${arr_type}_arr_el test_arr "$i" testvar
			printf '%s\n' "$testvar" >/dev/null
			# printf '%s\n' "${test_arr[$i]}" >/dev/null
		done
 	else
		for i in $elements; do
			get_${arr_type}_arr_el test_arr "abcdefghijklmn$i" testvar
			printf '%s\n' "$testvar" >/dev/null
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



arr_type="i"

# Warmup
f=1
n=10
elements=$(seq $f $n)
warmup

#echo "Indices after warmup:"
#eval "echo \"\$emu_i_test_arr_indices\""

# Test
f=1
n=1000

elements=$(seq $f $n)
__start_set=$(date +%s%N)
test_set
__end_set=$(date +%s%N)
 
__start_get_keys=$(date +%s%N)
if [ "$arr_type" = "i" ]; then
	get_i_arr_indices test_arr testvar
else
	get_a_arr_keys test_arr testvar
fi
printf '%s\n' "$testvar" >/dev/null
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
__start_add=$(date +%s%N)
test_add
__end_add=$(date +%s%N)
 


echo "set time: $(( (__end_set - __start_set)/timefactor )) $timeunits"

echo "get time: $(( (__end_get - __start_get)/timefactor )) $timeunits"
echo "get all time: $(( (__end_get_all - __start_get_all)/timefactor )) $timeunits"
echo "unset time: $(( (__end_unset - __start_unset)/timefactor )) $timeunits"
echo "add time: $(( (__end_add - __start_add)/timefactor )) $timeunits"
echo "get keys time: $(( (__end_get_keys - __start_get_keys)/timefactor )) $timeunits"

# echo "Resulting keys:"
# eval echo "\$___emu_${arr_type}_test_arr_keys"

# echo "Resulting values:"
# echo "'$resulting_values'"
