#!/bin/sh
# shellcheck disable=SC2154,SC2034

# emulate-array-test_set.sh

#### Initial setup
export LC_ALL=C

me=$(basename "$0")

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck disable=SC2015

. "$script_dir/emulate-array.sh" || { echo "$me: Error: Can't source '$script_dir/trim-subnet.sh'." >&2; exit 1; }


test_declare_wrong_i_arr() {
	declare_i_arr 2>/dev/null; declare_rv=$?
	[ $declare_rv -ne 1 ] && echo "test_declare_wrong_arr failed"
	unset declare_rv
}

test_declare_i_arr() {
# 1st line format: 'declare' function test
# 1st col: 'declare' function input args, 2nd col: return code

# 2nd and further line format is for 'get' function test_set
# 1st col: 'get function input args, 2nd col: expected values, 3rd col: expected return values

# '@' used as a delimiter

test_set_1="
test_arr@0
@@1
test_arr@@1
test_arr 0@@1
test_arr 1@@0
test_arr 2@@0
test_arr 1 2@@1
test_arr a@@1
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_2="
test_arr abc@0
@@1
test_arr@@1
test_arr 0@@1
test_arr 1@abc@0
test_arr 2@@0
test_arr 3@@0
test_arr 1 2@@1
test_arr a@@1
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_3="
test_arr abc 123@0
@@1
test_arr@@1
test_arr 0@@1
test_arr 1@abc@0
test_arr 2@123@0
test_arr 3@@0
test_arr 1 2@@1
test_arr a@@1
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_4="
test_arr abc 123 a@0
@@1
test_arr@@1
test_arr 0@@1
test_arr 1@abc@0
test_arr 2@123@0
test_arr 3@a@0
test_arr 1 2@@1
test_arr a@@1
test_arr 1 a@@1
test_arr a 1@@1
"

	test_id="$1"
	eval test_set="\$test_set_$test_id"

	# remove extra whitespaces, tabs and newlines
	test_set="$(printf "%s" "$test_set" | awk '$0=="" {next} {$1=$1};1')"

	test_set_lines_cnt="$(printf '%s\n' "$test_set" | wc -l)"
	test_header="$(printf '%s' "$test_set" | head -n1)"

	declare_str="${test_header%@*}"
	exp_declare_rv="${test_header#*@}"
	echo "declare_str: '$declare_str'"

	# shellcheck disable=SC2086
	declare_i_arr $declare_str 2>/dev/null; declare_rv=$?
	[ "$declare_rv" != "$exp_declare_rv" ] && echo "Error: test '$test_id', expected declare rv: '$exp_declare_rv', got declare rv: '$declare_rv'" >&2

	for i in $(seq 2 "$test_set_lines_cnt" ); do
		line="$(printf '%s\n' "$test_set" | awk "NR==$i")"
		in_args="${line%%@*}"
		other_stuff="${line#*@}"
		expected_val="${other_stuff%@*}"
		expected_rv="${other_stuff#*@}"

		# shellcheck disable=SC2086
		test_val="$(get_i_arr_el $in_args 2>/dev/null)"; rv=$?
		[ "$test_val" != "$expected_val" ] && echo "Error: test '$test_id', test line: '$line', expected val: '$expected_val', got val: '$test_val'" >&2
		[ "$rv" != "$expected_rv" ] && echo "Error: test '$test_id', test line: '$line', expected rv: '$expected_rv', got rv: '$rv'" >&2
	done
	arr_name="${declare_str%% *}"
	eval "unset emu_i_$arr_name"
	unset declare_str exp_declare_rv in_args other_stuff expected_val expected_rv test_val
}

test_declare_wrong_i_arr

echo "testing 'declare_i_arr' and 'get_i_arr_el'..."
for j in $(seq 1 4); do
	test_declare_i_arr "$j"
done





test_set_wrong_a_arr() {
	# shellcheck disable=SC2119
	set_a_arr_el 2>/dev/null; set_rv=$?
	[ $set_rv -ne 1 ] && echo "Error: test_set_wrong_arr failed. Expected rv: 1, got rv: '$set_rv'"
}

test_a_arr() {
# 1st line format: 'set' function test
# 1st col: 'set' function input args, 2nd col: return code

# 2nd and further line format is for 'get' function test_set
# 1st col: 'get function input args, 2nd col: expected values, 3rd col: expected return values

# '@' used as a delimiter

test_set_1="
set_a_arr_el test_arr@1
@@1
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr 1 2@@1
test_arr a@@0
test_arr abc@@0
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_2="
set_a_arr_el test_arr abc@1
@@1
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr 1 2@@1
test_arr a@@0
test_arr abc@@0
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_3="
set_a_arr_el test_arr abc 123@1
@@1
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr 1 2@@1
test_arr a@@0
test_arr abc@@0
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_4="
set_a_arr_el test_arr abc 123=a@1
@@1
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr 1 2@@1
test_arr a@@0
test_arr abc@@0
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_5="
set_a_arr_el test_arr 123=a abc@1
@@1
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr 1 2@@1
test_arr a@@0
test_arr abc@@0
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_6="
set_a_arr_el test_arr 123=a abc=d@1
@@1
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr 1 2@@1
test_arr a@@0
test_arr abc@@0
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_7="
set_a_arr_el test_arr 123=abcd@0
@@1
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr 1 2@@1
test_arr a@@0
test_arr abcd@@0
test_arr 123@abcd@0
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_8="
set_a_arr_el test_arr 123=abcd@0
set_a_arr_el test_arr abcd=123@0
@@1
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr 1 2@@1
test_arr a@@0
test_arr abcd@123@0
test_arr 123@abcd@0
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_9="
set_a_arr_el test_arr 123=abcd@0
set_a_arr_el test_arr abcd=123@0
set_a_arr_el test_arr aghk=a123@0
set_a_arr_el test_arr 1ghk=b123@0
@@1
test_arr 1ghk@b123@0
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr aghk@a123@0
test_arr 1 2@@1
test_arr a@@0
test_arr 123@abcd@0
test_arr abcd@123@0
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_10="
set_a_arr_el test_arr 123=abcd@0
set_a_arr_el test_arr abcd=123@0
set_a_arr_el test_arr abcd=jjjj@0
set_a_arr_el test_arr 123=@0
@@1
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr 1 2@@1
test_arr a@@0
test_arr 123@@0
test_arr abcd@jjjj@0
test_arr 1 a@@1
test_arr a 1@@1
"
test_set_11="
set_a_arr_el test_arr 123=abcd@0
set_a_arr_el test_arr abcd=123@0
set_a_arr_el test_arr abcd=jjjj@0
set_a_arr_el test_arr 123=@0
set_a_arr_el test_arr abcd=@0
@@1
test_arr@@1
test_arr 0@@0
test_arr 1@@0
test_arr 1 2@@1
test_arr a@@0
test_arr 123@@0
test_arr abcd@@0
test_arr 1 a@@1
test_arr a 1@@1
"

	test_id="$1"
	eval test_set="\$test_set_$test_id"

	# remove extra whitespaces, tabs and newlines
	test_set="$(printf "%s" "$test_set" | awk '$0=="" {next} {$1=$1};1')"

	# separate 'set' lines (header) from 'get' commands
	test_header="$(printf '%s' "$test_set" | grep 'set_a_arr_el')"
	test_header_lines_cnt="$(printf '%s\n' "$test_header" | wc -l)"
	echo "header lines: $test_header_lines_cnt"

	test_set="$(printf '%s' "$test_set" | tail -n+"$((test_header_lines_cnt+1))")"
	test_set_lines_cnt="$(printf '%s\n' "$test_set" | wc -l)"

	# execute 'set' commands
	for i in $(seq 1 "$test_header_lines_cnt"); do
		header_line="$(printf '%s\n' "$test_header" | awk "NR==$i")"
		set_command="${header_line%@*}"
		exp_set_rv="${header_line#*@}"
		echo "set_command: '$set_command'"
		eval "$set_command" 2>/dev/null; set_rv=$?
		[ "$set_rv" != "$exp_set_rv" ] && echo "Error: test '$test_id', expected set rv: '$exp_set_rv', got set rv: '$set_rv'" >&2
	done

	# execute 'get' commands
	for i in $(seq 1 "$test_set_lines_cnt" ); do
		line="$(printf '%s\n' "$test_set" | awk "NR==$i")"
		in_args="${line%%@*}"
		other_stuff="${line#*@}"
		expected_val="${other_stuff%@*}"
		expected_rv="${other_stuff#*@}"

		# shellcheck disable=SC2086
		test_val="$(get_a_arr_el $in_args 2>/dev/null)"; rv=$?
		[ "$test_val" != "$expected_val" ] && echo "Error: test '$test_id', test line: '$line', expected val: '$expected_val', got val: '$test_val'" >&2
		[ "$rv" != "$expected_rv" ] && echo "Error: test '$test_id', test line: '$line', expected rv: '$expected_rv', got rv: '$rv'" >&2
	done
	unset emu_a_test_arr
}

echo
test_set_wrong_a_arr

echo
echo "testing 'set_a_arr_el' and 'get_a_arr_el'..."
for j in $(seq 1 11); do
	test_a_arr "$j"
done




# declare_i_arr ahrttr_asdfasdfasdf asdfasdfasdfasdfasdfasfasfs123 r t aasdf asdfasdf asdfasdfsdfs asdfsdfsdfdsf asdfsdf 1>/dev/null
# for i in $(seq 1 1000); do
# 	get_i_arr_el ahrttr_asdfasdfasdf 7 1>/dev/null
# done
