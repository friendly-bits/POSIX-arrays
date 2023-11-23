#!/bin/sh
# shellcheck disable=SC2154,SC2034

# emulate-arrays-tests.sh

#### Initial setup
export LC_ALL=C

me=$(basename "$0")

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck disable=SC2015

. "$script_dir/emulate-array.sh" || { echo "$me: Error: Can't source '$script_dir/trim-subnet.sh'." >&2; exit 1; }


declare_wrong_i_arr() {
	# shellcheck disable=SC2119
	declare_i_arr 2>/dev/null; rv=$?
	[ $rv -ne 1 ] && echo "declare_wrong_i_arr failed"
	unset rv
}

test_i_arr() {
# 1st line format: 'declare' function test
# 1st col: 'declare' function input args, 2nd col: return code

# 2nd and further line format is for 'get' function tests
# 1st col: 'get function input args, 2nd col: expected values, 3rd col: expected return values

# '@' used as a delimiter

tests_1="
declare_i_arr arr@0
@@1
arr@@1
arr 0@@1
arr 1@@0
arr 2@@0
arr 1 2@@1
arr a@@1
arr 1 a@@1
arr a 1@@1
"
tests_2="
declare_i_arr arr abc@0
@@1
arr@@1
arr 0@@1
arr 1@abc@0
arr 2@@0
arr 3@@0
arr 1 2@@1
arr a@@1
arr 1 a@@1
arr a 1@@1
"
tests_3="
declare_i_arr arr abc 123@0
@@1
arr@@1
arr 0@@1
arr 1@abc@0
arr 2@123@0
arr 3@@0
arr 1 2@@1
arr a@@1
arr 1 a@@1
arr a 1@@1
"
tests_4="
declare_i_arr arr abc 123 a@0
@@1
arr@@1
arr 0@@1
arr 1@abc@0
arr 2@123@0
arr 3@a@0
arr 1 2@@1
arr a@@1
arr 1 a@@1
arr a 1@@1
"
tests_5="
declare_i_arr arr abc 123 \"a bcd 123\"@0
@@1
arr@@1
arr 0@@1
arr 1@abc@0
arr 2@123@0
arr 3@a bcd 123@0
arr 4@@0
arr 1 2@@1
arr a@@1
arr 1 a@@1
arr a 1@@1
"

	id="$1"
	eval "tests=\"\$tests_$id\""

	# remove extra whitespaces, tabs and newlines
	tests="$(printf "%s" "$tests" | awk '$0=="" {next} {$1=$1};1')"

	# separate 'declare' lines (header) from 'get' commands
	header="$(printf '%s' "$tests" | grep 'declare_i_arr')"
	header_lines_cnt="$(printf '%s\n' "$header" | wc -l)"
	echo "header lines: $header_lines_cnt"

	tests="$(printf '%s' "$tests" | tail -n+"$((header_lines_cnt+1))")"
	lines_cnt="$(printf '%s\n' "$tests" | wc -l)"

	# execute 'declare' commands
	for i in $(seq 1 "$header_lines_cnt"); do
		header_line="$(printf '%s\n' "$header" | awk "NR==$i")"
		test_command="${header_line%@*}"
		exp_rv="${header_line#*@}"
		echo "test_command: '$test_command'"
		eval "$test_command" 2>/dev/null; rv=$?
		[ "$rv" != "$exp_rv" ] && echo "Error: test '$id', expected rv: '$exp_rv', got rv: '$rv'" >&2
	done

	# execute 'get' commands
	for i in $(seq 1 "$lines_cnt" ); do
		line="$(printf '%s\n' "$tests" | awk "NR==$i")"
		in_args="${line%%@*}"
		other_stuff="${line#*@}"
		expected_val="${other_stuff%@*}"
		expected_rv="${other_stuff#*@}"

		# shellcheck disable=SC2086
		val="$(get_i_arr_el $in_args 2>/dev/null)"; rv=$?
		[ "$val" != "$expected_val" ] && echo "Error: test '$id', test line: '$line', expected val: '$expected_val', got val: '$val'" >&2
		[ "$rv" != "$expected_rv" ] && echo "Error: test '$id', test line: '$line', expected rv: '$expected_rv', got rv: '$rv'" >&2
	done
	unset emu_i_arr
	unset declare_str exp_declare_rv in_args other_stuff expected_val expected_rv val
}

declare_wrong_i_arr

echo "testing 'declare_i_arr' and 'get_i_arr_el'..."
for j in $(seq 1 5); do
	test_i_arr "$j"
done





wrong_a_arr() {
	# shellcheck disable=SC2119
	set_a_arr_el 2>/dev/null; rv=$?
	[ $rv -ne 1 ] && echo "Error: set_wrong_arr failed. Expected rv: 1, got rv: '$rv'"
}

test_a_arr() {
# 1st line format: 'set' function test
# 1st col: 'set' function input args, 2nd col: return code

# 2nd and further line format is for 'get' function tests
# 1st col: 'get function input args, 2nd col: expected values, 3rd col: expected return values

# '@' used as a delimiter

tests_1="
set_a_arr_el arr@1
@@1
arr@@1
arr 0@@0
arr 1@@0
arr 1 2@@1
arr a@@0
arr abc@@0
arr 1 a@@1
arr a 1@@1
"
tests_2="
set_a_arr_el arr abc@1
@@1
arr@@1
arr 0@@0
arr 1@@0
arr 1 2@@1
arr a@@0
arr abc@@0
arr 1 a@@1
arr a 1@@1
"
tests_3="
set_a_arr_el arr abc 123@1
@@1
arr@@1
arr 0@@0
arr 1@@0
arr 1 2@@1
arr a@@0
arr abc@@0
arr 1 a@@1
arr a 1@@1
"
tests_4="
set_a_arr_el arr abc 123=a@1
@@1
arr@@1
arr 0@@0
arr 1@@0
arr 1 2@@1
arr a@@0
arr abc@@0
arr 1 a@@1
arr a 1@@1
"
tests_5="
set_a_arr_el arr 123=a abc@1
@@1
arr@@1
arr 0@@0
arr 1@@0
arr 1 2@@1
arr a@@0
arr abc@@0
arr 1 a@@1
arr a 1@@1
"
tests_6="
set_a_arr_el arr 123=a abc=d@1
@@1
arr@@1
arr 0@@0
arr 1@@0
arr 1 2@@1
arr a@@0
arr abc@@0
arr 1 a@@1
arr a 1@@1
"
tests_7="
set_a_arr_el arr 123=abcd@0
@@1
arr@@1
arr 0@@0
arr 1@@0
arr 1 2@@1
arr a@@0
arr abcd@@0
arr 123@abcd@0
arr 1 a@@1
arr a 1@@1
"
tests_8="
set_a_arr_el arr 123=abcd@0
set_a_arr_el arr abcd=123@0
@@1
arr@@1
arr 0@@0
arr 1@@0
arr 1 2@@1
arr a@@0
arr abcd@123@0
arr 123@abcd@0
arr 1 a@@1
arr a 1@@1
"
tests_9="
set_a_arr_el arr 123=abcd@0
set_a_arr_el arr abcd=123@0
set_a_arr_el arr aghk=a123@0
set_a_arr_el arr 1ghk=b123@0
@@1
arr 1ghk@b123@0
arr@@1
arr 0@@0
arr 1@@0
arr aghk@a123@0
arr 1 2@@1
arr a@@0
arr 123@abcd@0
arr abcd@123@0
arr 1 a@@1
arr a 1@@1
"
tests_10="
set_a_arr_el arr 123=abcd@0
set_a_arr_el arr abcd=123@0
set_a_arr_el arr abcd=jjjj@0
set_a_arr_el arr 123=@0
@@1
arr@@1
arr 0@@0
arr 1@@0
arr 1 2@@1
arr a@@0
arr 123@@0
arr abcd@jjjj@0
arr 1 a@@1
arr a 1@@1
"
tests_11="
set_a_arr_el arr 123=abcd@0
set_a_arr_el arr abcd=123@0
set_a_arr_el arr abcd=jjjj@0
set_a_arr_el arr 123=@0
set_a_arr_el arr abcd=@0
@@1
arr@@1
arr 0@@0
arr 1@@0
arr 1 2@@1
arr a@@0
arr 123@@0
arr abcd@@0
arr 1 a@@1
arr a 1@@1
"
tests_12="
set_a_arr_el arr 123=\"abcd efgh 123\"@0
set_a_arr_el arr abcd=123@0
set_a_arr_el arr aghk=a123@0
set_a_arr_el arr 1ghk=b123@0
@@1
arr 1ghk@b123@0
arr@@1
arr 0@@0
arr 1@@0
arr aghk@a123@0
arr 1 2@@1
arr a@@0
arr 123@abcd efgh 123@0
arr abcd@123@0
arr 1 a@@1
arr a 1@@1
"

	id="$1"
	eval "tests=\"\$tests_$id\""

	# remove extra whitespaces, tabs and newlines
	tests="$(printf "%s" "$tests" | awk '$0=="" {next} {$1=$1};1')"

	# separate 'set' lines (header) from 'get' commands
	header="$(printf '%s' "$tests" | grep 'set_a_arr_el')"
	header_lines_cnt="$(printf '%s\n' "$header" | wc -l)"
	echo "header lines: $header_lines_cnt"

	tests="$(printf '%s' "$tests" | tail -n+"$((header_lines_cnt+1))")"
	tests_lines_cnt="$(printf '%s\n' "$tests" | wc -l)"

	# execute 'set' commands
	for i in $(seq 1 "$header_lines_cnt"); do
		header_line="$(printf '%s\n' "$header" | awk "NR==$i")"
		test_command="${header_line%@*}"
		exp_rv="${header_line#*@}"
		echo "test_command: '$test_command'"
		eval "$test_command" 2>/dev/null; rv=$?
		[ "$rv" != "$exp_rv" ] && echo "Error: test '$id', expected rv: '$exp_rv', got rv: '$rv'" >&2
	done

	# execute 'get' commands
	for i in $(seq 1 "$tests_lines_cnt" ); do
		line="$(printf '%s\n' "$tests" | awk "NR==$i")"
		in_args="${line%%@*}"
		other_stuff="${line#*@}"
		expected_val="${other_stuff%@*}"
		expected_rv="${other_stuff#*@}"

		# shellcheck disable=SC2086
		val="$(get_a_arr_el $in_args 2>/dev/null)"; rv=$?
		[ "$val" != "$expected_val" ] && echo "Error: test '$id', test line: '$line', expected val: '$expected_val', got val: '$val'" >&2
		[ "$rv" != "$expected_rv" ] && echo "Error: test '$id', test line: '$line', expected rv: '$expected_rv', got rv: '$rv'" >&2
	done
	unset emu_a_arr
}

echo
wrong_a_arr

echo
echo "testing 'set_a_arr_el' and 'get_a_arr_el'..."
for j in $(seq 1 12); do
	test_a_arr "$j"
done




# declare_i_arr ahrttr_asdfasdfasdf asdfasdfasdfasdfasdfasfasfs123 r t aasdf asdfasdf asdfasdfsdfs asdfsdfsdfdsf asdfsdf 1>/dev/null
# for i in $(seq 1 1000); do
# 	get_i_arr_el ahrttr_asdfasdfasdf 7 1>/dev/null
# done

# declare_i_arr arr1 a b "1 2 3"
# get_i_arr_el arr1 3
