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
	test="$3"
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
	while [ -n "$header" ]; do
		# get line/s for the next command
		header_line="$(printf '%s\n' "$header" | \
			sed -n -e /"_${arr_type}_arr"/\{:1 -e p\;n\;/"_${arr_type}_arr"/q\;b1 -e \})"
		# remove next command line/s from the list
		header="${header#"$header_line"}"; header="${header#?}"
		# extract test specifics
		test_command="${header_line%@*}"
		expected_rv="${header_line#*@}"
		echo "**header test_command: '$test_command'"

		# gather array names from the test to reset the variables in the end
		arr_name="$(printf '%s' "$test_command" | head -n1 | cut -d' ' -f2)"
		case "$arr_name" in *_arr_* ) ;; *) arr_names="${arr_name}${newline}${arr_names}"; esac

		if [ -z "$print_stderr" ]; then eval "$test_command" 2>/dev/null; rv=$?
		else eval "$test_command"; rv=$?
		fi
		
		[ "$rv" != "$expected_rv" ] && {
			echo "Error: test '$id', expected rv: '$expected_rv', got rv: '$rv'" >&2
			err_num=$((err_num+1)); }
	done

	# execute the 'get' commands
	while [ -n "$test" ]; do
		# get line/s for the next command
		line="$(printf '%s\n' "$test" | \
			sed -n -e /"_${arr_type}_arr"/\{:1 -e p\;n\;/"_${arr_type}_arr"/q\;b1 -e \})"
		# remove next command line/s from the list
		test="${test#"$line"}"; test="${test#?}"
		# extract test specifics
		test_command="${line%%@*}"
		other_stuff="${line#*@}"
		expected_val="${other_stuff%@*}"
		expected_rv="${other_stuff#*@}"

		# shellcheck disable=SC2086
		if [ -z "$print_stderr" ]; then val="$($test_command 2>/dev/null)"; rv=$?
		else val="$($test_command)"; rv=$?
		fi

		[ "$val" != "$expected_val" ] && {
			echo "Error: test '$id', test line: '$line', expected val: '$expected_val', got val: '$val'" >&2
			err_num=$((err_num+1)); }
		[ "$rv" != "$expected_rv" ] && {
			echo "Error: test '$id', test line: '$line', expected rv: '$expected_rv', got rv: '$rv'" >&2
			err_num=$((err_num+1)); }
		printf '%s' "."
	done
	printf '\n'

	arr_names="$(printf '%s\n' "$arr_names" | sort -u)"
	for arr_name in $arr_names; do
		unset "emu_${arr_type}_${arr_name}" 2>/dev/null
	done
	unset test_command other_stuff expected_val expected_rv val arr_names
}


run_test_a_arr() {
	. "$script_dir/tests-set_a_arr.list"
	echo
	echo "*** Testing 'set_a_arr_el' and 'get_a_arr_el'... ***"
	first_test=${1:-1}
	last_test=${2:-100}
	j="$first_test"
	test="$test_1"
	while [ -n "$test" ] && [ "$j" -le "$last_test" ]; do
		tests_list="test_$j $tests_list"
		run_test "$j" a "$test"
		j=$((j+1))
		eval "test=\"\$test_$j\""
	done
	unset $tests_list; unset tests
}

run_test_set_i_arr() {
	. "$script_dir/tests-set_i_arr.list"
	echo
	echo "*** Testing 'set_i_arr_el' and 'get_i_arr_el'... ***"
	first_test=${1:-1}
	last_test=${2:-100}
	j="$first_test"
	test="$test_1"
	while [ -n "$test" ] && [ "$j" -le "$last_test" ]; do
		tests_list="test_$j $tests_list"
		run_test "$j" i "$test"
		j=$((j+1))
		eval "test=\"\$test_$j\""
	done
	unset $tests_list; unset tests
}

run_test_declare_i_arr() {
	. "$script_dir/tests-declare_i_arr.list"
	echo
	echo "*** Testing 'declare_i_arr' and 'get_i_arr_el'... ***"
	first_test=${1:-1}
	last_test=${2:-100}
	j="$first_test"
	test="$test_1"
	while [ -n "$test" ] && [ "$j" -le "$last_test" ]; do
		tests_list="test_$j $tests_list"
		run_test "$j" i "$test"
		j=$((j+1))
		eval "test=\"\$test_$j\""
	done
	unset $tests_list; unset tests
}


#### Main

newline="
"

#print_stderr=true

err_num=0
run_test_declare_i_arr
run_test_set_i_arr
run_test_a_arr
printf '\n%s\n' "Total errors: $err_num."

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
