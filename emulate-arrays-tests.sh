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

	arr_type="$1"
	test_file="$2"
	first_test_num=${3:-1}
	last_test_num=${4:-100}

	# shellcheck disable=SC1090
	. "$test_file" || { echo "$me: Error: Can't source '$test_file'." >&2; exit 1; }

	k="$first_test_num"

	# load the first test unit
	eval "test_unit=\"\$test_$k\""
	[ -z "$test_unit" ] && { echo "$me: Error: failed to load the test unit for 'test_$k'." >&2; exit 1; }

	while [ -n "$test_unit" ] && [ "$k" -le "$last_test_num" ]; do
		# gather test variables names to unset them later
		test_var_names="test_$k $test_var_names"

		test_id="$k"
		echo; echo "Test id: $test_id."

		# remove extra whitespaces, tabs and newlines
		test_unit="$(printf "%s" "$test_unit" | awk '$0=="" {next} {$1=$1};1')"

		## separate 'declare' lines (header) from 'get' commands
		# get the header lines
		header_test_unit="$(printf '%s\n' "$test_unit" | \
			sed -n -e /"\[header\]"/\{:1 -e n\;/"\[\/header\]"/q\;p\;b1 -e \})"
		header_lines_cnt="$(printf '%s\n' "$header_test_unit" | wc -l)"

		# get the main test lines
		main_test_unit="$(printf '%s' "$test_unit" | tail -n+"$((header_lines_cnt+3))")"
		main_lines_cnt="$(printf '%s\n' "$test_unit" | wc -l)"

		# execute 'declare' and 'set' commands
		while [ -n "$header_test_unit" ]; do
			# get line/s for the next command
			header_line="$(printf '%s\n' "$header_test_unit" | \
				sed -n -e /"_${arr_type}_arr"/\{:1 -e p\;n\;/"_${arr_type}_arr"/q\;b1 -e \})"
			# remove next command line/s from the list
			header_test_unit="${header_test_unit#"$header_line"}"; header_test_unit="${header_test_unit#?}"
			# extract test unit specifics
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
				printf '\n%s\n' "Error: test '$test_id', header line: '$header_line', expected rv: '$expected_rv', got rv: '$rv'" >&2
				err_num=$((err_num+1)); }
		done

		# execute the 'get' commands
		while [ -n "$main_test_unit" ]; do
			# get line/s for the next command
			line="$(printf '%s\n' "$main_test_unit" | \
				sed -n -e /"_${arr_type}_arr"/\{:1 -e p\;n\;/"_${arr_type}_arr"/q\;b1 -e \})"
			# remove line/s for the next command from the list
			main_test_unit="${main_test_unit#"$line"}"; main_test_unit="${main_test_unit#?}"
			# extract test unit specifics
			test_command="${line%%@*}"
			other_stuff="${line#*@}"
			expected_val="${other_stuff%@*}"
			expected_rv="${other_stuff#*@}"

			# shellcheck disable=SC2086
			if [ -z "$print_stderr" ]; then val="$($test_command 2>/dev/null)"; rv=$?
			else val="$($test_command)"; rv=$?
			fi

			[ "$val" != "$expected_val" ] && {
				printf '\n%s\n' "Error: test '$test_id', test line: '$line', expected val: '$expected_val', got val: '$val'" >&2
				err_num=$((err_num+1)); }
			[ "$rv" != "$expected_rv" ] && {
				printf '\n%s\n' "Error: test '$test_id', test line: '$line', expected rv: '$expected_rv', got rv: '$rv'" >&2
				err_num=$((err_num+1)); }
			printf '%s' "."
		done
		printf '\n'

		# unset the variables holding the arrays
		arr_names="$(printf '%s\n' "$arr_names" | sort -u)"
		for arr_name in $arr_names; do
			unset "emu_${arr_type}_${arr_name}" 2>/dev/null
		done
		unset test_command other_stuff expected_val expected_rv val arr_names

		# load the next test unit
		k=$((k+1))
		eval "test_unit=\"\$test_$k\""
	done

	# shellcheck disable=SC2086
	# unset the variables holding the test units
	unset $test_var_names; unset test_var_names
}


run_test_a_arr() {
	first_test_num=$1; last_test_num=$2; arr_type="a"
	test_file="$script_dir/tests-set_a_arr.list"
	echo; echo "*** Testing 'set_a_arr_el' and 'get_a_arr_el'... ***"
	run_test "$arr_type" "$test_file" "$first_test_num" "$last_test_num"
}

run_test_set_i_arr() {
	first_test_num=$1; last_test_num=$2; arr_type="i"
	test_file="$script_dir/tests-set_i_arr.list"
	echo; echo "*** Testing 'set_i_arr_el' and 'get_i_arr_el'... ***"
	run_test "$arr_type" "$test_file" "$first_test_num" "$last_test_num"
}

run_test_declare_i_arr() {
	first_test_num=$1; last_test_num=$2; arr_type="i"
	test_file="$script_dir/tests-declare_i_arr.list"
	echo; echo "*** Testing 'declare_i_arr' and 'get_i_arr_el'... ***"
	run_test "$arr_type" "$test_file" "$first_test_num" "$last_test_num"
}


#### Main

newline="
"

# To print errors returned by the functions under test, uncomment the following line
# Some of the test units intentionally induce errors, so expect an error spam in the console

# print_stderr=true

err_num=0

# To only run a specific test set, comment out some of the following lines starting with run_test_
# To limit to sepcific test units, use this format run_test_* [first_test_num_number] [last_test_num_number]
# For example, 'run_test_a_arr 5 8' will run test units 5 through 8
run_test_declare_i_arr
run_test_set_i_arr
run_test_a_arr

printf '\n%s\n' "Total errors: $err_num."


### Performance tests

#  n=1400

# for i in $(seq 1 $n); do
# 	set_i_arr_el test_arr "$i" "a$i"
# #	test="$(get_i_arr_el test_arr "$((n+1-i))")"
# done

# for i in $(seq 1 $n); do
# 	get_i_arr_el test_arr "$i" >/dev/null
# 	#echo "$test"
# done

# for i in $(seq 1 $n); do
# 	set_a_arr_el test_arr "$i=a$i"
# 	test="$(get_a_arr_el test_arr "$((n+1-i))")"
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
