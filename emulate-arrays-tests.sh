#!/bin/sh
# shellcheck disable=SC2154,SC2034,SC2120

# emulate-arrays-tests.sh

#### Initial setup
export LC_ALL=C
me=$(basename "$0")

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck disable=SC2015

. "$script_dir/emulate-arrays.sh" || { echo "$me: Error: Can't source '$script_dir/emulate-arrays.sh'." >&2; exit 1; }


#### Functions

run_test() {
# Test sets use '@' as a column delimiter
# 1st 1 or more lines format: 'declare' or 'set' function tests
# 1st col: function call with input args, 2nd col: expected return code

# further lines format is for 'get' function tests
# 1st col: 'get' function call with input args, 2nd col: expected value, 3rd col: expected return code

	id="$1"
	arr_type="$2"
	eval "test=\"\$test_$id\""
	echo; echo "Test id: $id."

	# remove extra whitespaces, tabs and newlines
	test="$(printf "%s" "$test" | awk '$0=="" {next} {$1=$1};1')"

	## separate 'declare' lines (header) from 'get' commands
	# get the header lines
	header="$(printf '%s\n' "$test" | sed -n -e /"\[header\]"/\{:1 -e n\;/"\[\/header\]"/q\;p\;b1 -e \})"
	header_lines_cnt="$(printf '%s\n' "$header" | wc -l)"

	# get the test lines
	test="$(printf '%s' "$test" | tail -n+"$((header_lines_cnt+3))")"
	lines_cnt="$(printf '%s\n' "$test" | wc -l)"

	# execute 'declare' and 'set' commands
	for i in $(seq 1 "$header_lines_cnt"); do
		header_line="$(printf '%s\n' "$header" | awk "NR==$i")"
		test_command="${header_line%@*}"
		expected_rv="${header_line#*@}"
		echo "test_command: '$test_command'"

		# gather array names from the test to reset the variables in the end
		arr_name="$(printf '%s' "$test_command" | cut -d' ' -f2)"
		case "$arr_name" in *_i_arr_* ) ;; *) arr_names="${arr_name}${newline}${arr_names}"; esac

		if [ -z "$print_stderr" ]; then eval "$test_command" 2>/dev/null; rv=$?
		else eval "$test_command"; rv=$?
		fi
		
		[ "$rv" != "$expected_rv" ] && echo "Error: test '$id', expected rv: '$expected_rv', got rv: '$rv'" >&2
	done

	# execute the 'get' commands
	for i in $(seq 1 "$lines_cnt" ); do
		line="$(printf '%s\n' "$test" | awk "NR==$i")"
		test_command="${line%%@*}"
		other_stuff="${line#*@}"
		expected_val="${other_stuff%@*}"
		expected_rv="${other_stuff#*@}"

		# shellcheck disable=SC2086
		if [ -z "$print_stderr" ]; then val="$($test_command 2>/dev/null)"; rv=$?
		else val="$($test_command)"; rv=$?
		fi

		[ "$val" != "$expected_val" ] && echo "Error: test '$id', test line: '$line', expected val: '$expected_val', got val: '$val'" >&2
		[ "$rv" != "$expected_rv" ] && echo "Error: test '$id', test line: '$line', expected rv: '$expected_rv', got rv: '$rv'" >&2
		printf '%s' "."
	done
	printf '\n'

	arr_names="$(printf '%s\n' "$arr_names" | sort -u)"
	for arr_name in $arr_names; do
		unset "emu_${arr_type}_${arr_name}"
	done
	unset test_command other_stuff expected_val expected_rv val arr_names
}


run_test_a_arr() (
	. "$script_dir/tests-set_a_arr.list"
	echo
	echo "*** testing 'set_a_arr_el' and 'get_a_arr_el'... ***"
	next_test="start"
	first_test=${1:-1}
	last_test=${2:-100}
	j="$first_test"
	while [ -n "$next_test" ] && [ "$j" -le "$last_test" ]; do
		run_test "$j" a
		j=$((j+1))
		eval "next_test=\"\$test_$j"\"
	done
)

run_test_set_i_arr() (
	. "$script_dir/tests-set_i_arr.list"
	echo
	echo "*** testing 'set_i_arr_el' and 'get_i_arr_el'... ***"
	next_test="start"
	first_test=${1:-1}
	last_test=${2:-100}
	j="$first_test"
	while [ -n "$next_test" ] && [ "$j" -le "$last_test" ]; do
		run_test "$j" i
		j=$((j+1))
		eval "next_test=\"\$test_$j"\"
	done
)

run_test_declare_i_arr() (
	. "$script_dir/tests-declare_i_arr.list"
	echo
	echo "*** testing 'declare_i_arr' and 'get_i_arr_el'... ***"
	next_test="start"

	first_test=${1:-1}
	last_test=${2:-100}
	j="$first_test"
	while [ -n "$next_test" ] && [ "$j" -le "$last_test" ]; do
		run_test "$j" i
		j=$((j+1))
		eval "next_test=\"\$test_$j"\"
	done
)


#### Main

newline="
"

#print_stderr=true

run_test_declare_i_arr
run_test_set_i_arr
run_test_a_arr


### Performance tests

# n=1000

# for i in $(seq 1 $n); do
# 	set_i_arr_el test_arr "$i" "a$i"
# 	test="$(get_i_arr_el test_arr "$((n+1-i))")"
# done

# for i in $(seq 1 $n); do
# 	set_a_arr_el test_arr "$i=a$i"
# 	test="$(get_a_arr_el test_arr "$((n+1-i))")"
# done

# for i in $(seq 1 $n); do
# 	get_i_arr_el test_arr "$i" >/dev/null
# 	#echo "$test"
# done




# for i in $(seq 1000 1600); do
# 	set_i_arr_el test_arr "$i" "x"
# done
 
# ### performance - START
 
# n=500
# for i in $(seq 1 $n); do
# 	set_i_arr_el test_arr "$i" "a"
# 	get_i_arr_el test_arr "$i" >/dev/null
# 	set_i_arr_el test_arr "$i" "b"
# 	get_i_arr_el test_arr "$i" >/dev/null
# 	set_i_arr_el test_arr "$i" "c"
# 	get_i_arr_el test_arr "$i" >/dev/null
# done
