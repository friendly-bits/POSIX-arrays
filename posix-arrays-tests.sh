#!/bin/sh
# shellcheck disable=SC2154,SC2034,SC2120

# posix-arrays-tests.sh

#### Initial setup
export LC_ALL=C
me=$(basename "$0")

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck disable=SC2015

. "$script_dir/posix-arrays.sh" || { echo "$me: Error: Can't source '$script_dir/posix-arrays.sh'." >&2; exit 1; }


#### Functions

# outputs first N lines from input
# faster than head for a small (< 100) number of lines
fast_head() {
	in_lines="$1"; lines_num="$2"
	IFS_OLD="$IFS"; IFS="$newline"; set -f
	i=1
	for in_line in $in_lines; do
		case $(( lines_num < i )) in 1) break; esac
		printf '%s\n' "$in_line"
		i=$((i+1))
	done
	IFS="$IFS_OLD"; set +f
	unset in_lines lines_num i
}


# outputs lines from input, starting from line N
# similar to 'tail -n+[N]' command, only fast
# may work incorrectly if too many lines provided as input
from_line() {
	in_lines="$1"; line_ind=$(($2-1))
	IFS_OLD="$IFS"; IFS="$newline"; set -f
	# shellcheck disable=SC2086
	set -- $in_lines
	shift $line_ind
	# shellcheck disable=SC2048,SC2086
	printf '%s\n' $*
	IFS="$IFS_OLD"; set +f
}


run_test() {
# Test units use '@' as a column delimiter
# test_init lines format:
# 1st col: function call with input args, 2nd col: expected return code

# Further lines format:
# 1st col: function call with input args, 2nd col: expected value, 3rd col: expected return code


	arr_type="$1"
	test_file="$2"
	first_test_num=${3:-1}
	last_test_num=${4:-100}

	# shellcheck disable=SC1090
	. "$test_file" || { echo "$me: Error: Can't source '$test_file'." >&2; exit 1; }

	k="$first_test_num"

	# load the first test unit
	eval "test_unit=\"\$test_$k\""
	case "$test_unit" in '') echo "$me: Error: failed to load the test unit for 'test_$k'." >&2; exit 1; esac

	while true; do
		case "$test_unit" in '') break; esac
		case $((last_test_num - k)) in -*) break; esac

		# gather test variables names to unset them later
		test_var_names="test_$k $test_var_names"

		test_id="$k"
		echo; echo "Test id: $test_id."

		# remove extra whitespaces, tabs and newlines
		test_unit="$(printf "%s" "$test_unit" | awk '$0=="" {next} {$1=$1};1')"

		## separate 'declare' lines (test_init) from 'get' commands
		# get the init lines
		init_test_unit="$(printf '%s\n' "$test_unit" | \
			sed -n -e /"\[test_init\]"/\{:1 -e n\;/"\[\/test_init\]"/q\;p\;b1 -e \})"
		IFS_OLD="$IFS"; IFS="$newline"; set -f
		# shellcheck disable=SC2086
		set -- $init_test_unit
		init_lines_cnt=$#
		IFS="$IFS_OLD"; set +f

		# get the main test lines
		main_test_unit="$(from_line "$test_unit" $((init_lines_cnt+3)))"

		# execute 'declare' and 'set' commands
		while true; do
			case "$init_test_unit" in '') break; esac

			# get line/s for the next command
			init_line="$(printf '%s\n' "$init_test_unit" | \
				sed -n -e /"_${arr_type}_arr"/\{:1 -e p\;n\;/"_${arr_type}_arr"/q\;b1 -e \})"
			# remove next command line/s from the list
			init_test_unit="${init_test_unit#"$init_line"}"; init_test_unit="${init_test_unit#?}"
			# extract test unit specifics
			test_command="${init_line%@*}"
			expected_rv="${init_line#*@}"
			echo "**init command: '$test_command'"

			# gather array names from the test to reset the variables in the end
			arr_name="$(fast_head "$test_command" 1)"; arr_name="${arr_name#* }"; arr_name="${arr_name%% *}"
			case "$arr_name" in *_arr_*|-s ) ;; *) arr_names="${arr_name}${newline}${arr_names}"; esac

			case "$print_stderr" in
				'' ) eval "$test_command" 2>/dev/null; rv=$? ;;
				* )  eval "$test_command"; rv=$?
			esac

			case "$rv" in "$expected_rv" ) ;; * )
				printf '\n%s\n' "Error: test '$test_id', init line: '$init_line', expected rv: '$expected_rv', got rv: '$rv'" >&2
				err_num=$((err_num+1))
			esac

			tests_done=$((tests_done+1))
		done

		# execute the 'get' commands
		while true; do
			case "$main_test_unit" in '') break; esac
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

			val=''
			case "$print_stderr" in
				'' ) eval "$test_command" 2>/dev/null; rv=$? ;;
				* )  eval "$test_command"; rv=$?
			esac

			case "$val" in "$expected_val" ) ;; * )
				printf '\n%s\n' "Error: test '$test_id', test line: '$line', expected val: '$expected_val', got val: '$val'" >&2
				err_num=$((err_num+1))
			esac
			case "$rv" in "$expected_rv" ) ;; * )
				printf '\n%s\n' "Error: test '$test_id', test line: '$line', expected rv: '$expected_rv', got rv: '$rv'" >&2
				err_num=$((err_num+1))
			esac

			printf '%s' "."
			tests_done=$((tests_done+1))
		done
		printf '\n'

		# unset the variables holding the arrays
		arr_names="$(printf '%s\n' "$arr_names" | sort -u)"
		for arr_name in $arr_names; do
			# shellcheck disable=SC2086
			unset_${arr_type}_arr "$arr_name"
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


run_test_i_arr_1() {
	first_test_num=$1; last_test_num=$2; arr_type="i"
	test_file="$script_dir/tests-i_arr_1.list"
	echo; echo "*** Indexed arrays tests set 1... ***"
	run_test "$arr_type" "$test_file" "$first_test_num" "$last_test_num"
}

run_test_i_arr_2() {
	first_test_num=$1; last_test_num=$2; arr_type="i"
	test_file="$script_dir/tests-i_arr_2.list"
	echo; echo "*** Indexed arrays tests set 2... ***"
	run_test "$arr_type" "$test_file" "$first_test_num" "$last_test_num"
}

run_test_i_arr_3() {
	first_test_num=$1; last_test_num=$2; arr_type="i"
	test_file="$script_dir/tests-i_arr_3.list"
	echo; echo "*** Indexed arrays tests set 3... ***"
	run_test "$arr_type" "$test_file" "$first_test_num" "$last_test_num"
}

run_test_a_arr_1() {
	first_test_num=$1; last_test_num=$2; arr_type="a"
	test_file="$script_dir/tests-a_arr_1.list"
	echo; echo "*** Associative arrays tests set 1... ***"
	run_test "$arr_type" "$test_file" "$first_test_num" "$last_test_num"
}

run_test_a_arr_2() {
	first_test_num=$1; last_test_num=$2; arr_type="a"
	test_file="$script_dir/tests-a_arr_2.list"
	echo; echo "*** Associative arrays tests set 2... ***"
	run_test "$arr_type" "$test_file" "$first_test_num" "$last_test_num"
}


#### Main

newline="
"
trim_IFS="$(printf ' \t')"

# To print errors returned by the functions under test, uncomment the following line
# Some of the test units intentionally induce errors, so expect an error spam in the console

#print_stderr=true

err_num=0

# To only run a specific test set, comment out some of the following lines starting with run_test_
# To limit to sepcific test units, use this format run_test_* [first_test_num_number] [last_test_num_number]
# For example, 'run_test_a_arr 5 8' will run test units 5 through 8
run_test_i_arr_1
run_test_i_arr_2
run_test_i_arr_3
run_test_a_arr_1
run_test_a_arr_2

printf '\n%s\n' "Tests done: $tests_done."
printf '%s\n' "Total errors: $err_num."
