# POSIX-arrays
POSIX-compliant shell functions emulating some aspects of arrays.

## Usage
1) Source the script emulate-arrays.sh in your script like so: `. [path]/emulate-arrays.sh`
2) Call any function from the sourced script in your script.

Note that the last line in emulate-arrays.sh sets the delimiter variable. That variable needs to be set for the functions to work. If you want to use the functions without sourcing the script, you'll need to set that variable in your own script.

**Indexed arrays**:

`declare_i_arr <array_name> [value] [value] ... [value]` - resets the array and assigns values to sequential indices, starting from 0.

`set_i_arr_el <array_name> <index> [value]` - assigns `[value]` to `<index>`. Indices should always be nonnegative integer numbers. This acts as a sparse array, so indices don't have to be sequential. If `value` is an empty string, unsets the value.

`get_i_arr_el <array_name> <index>` - prints value for `<index>` from the indexed array.

`get_i_arr_values <array_name>` - prints all values from an indexed array as a sorted (by index) newline-separated list.

`get_i_arr_indices <array_name>` - prints all indices as a sorted newline-separated list.

`clean_i_arr <array_name>` - unsets all variables used to store the array in memory.

**Examples**:

Input:

```
set_i_arr_el test_arr 10 some_val
get_i_arr_el test_arr 10
```

Output: `some_val`

Input:

```
declare_i_arr test_arr val1 val2 "val 123 etc"
get_i_arr_el test_arr 2
```

Output: `val3 123 etc`

**Associative arrays**:

`declare_a_arr <array_name> [key=value] [key=value] ... [key=value]` - resets the array and assigns values to keys.

`set_a_arr_el <array_name> <key>=[value]` - assigns `value` to `key`. If `value` is an empty string, stores the empty string as a value for `key`.

`get_a_arr_el <array_name> <key>` - prints value for `key` from associative array.

`get_a_arr_values <array_name>` - prints all values as an alphabetically sorted (by key) newline-separated list.

`get_a_arr_keys <array_name>` - prints all keys as an alphabetically sorted newline-separated list.

`clean_a_arr <array_name>` - unsets all variables used to store the array in memory.

**Example**:

Input:

```
set_a_arr_el test_arr some_key="this is a test"
get_a_arr_el test_arr some_key
```

Output: `this is a test`

## Details
- The arrays can hold strings that have any characters in them, including whitespaces and newlines.
- Array names and (for associative arrays) keys are limited to alphanumeric characters and underlines - `_`.
- The indices start at 0
- As is default for shells, if you request a value corresponding to an index or to a key that has not been set previously, the functions will output an empty string and not return an error.
- The indexed array effectively works as a sparse array, meaning that the indices do not have to be sequential. For example, you can set a value for index 10 and for index 100 while all other indices will not be set.
- The declare functions are not necessary to create an array. It's just a way to set N elements in one command. Otherwise you can create an indexed array by simply calling the `set_i_arr_el()` function or an associative array by calling the `set_a_arr_el()` function.

## Performance
- The code is quite efficient for a shell script. It went through multiple rounds of optimization and quite a few different algorithms have been tested. Currently the performance for small arrays (<= 200 elements) is comparable to Bash arrays. The script performs reasonably well with arrays containing up to 1000 elements. Higher than that, the performance drops significanly. All that applies to performance on a fairly old x86 CPU.
- While the code works if run under Bash or probably any other Unix-compatible shell, it runs much faster in a simpler shell like Dash. In my comparison it was about 3x faster under Dash compared to Bash.

<details> <summary>Benchmarks:</summary>


Measured on i7-4770 with 40-characters strings in each element:


10 elements array:

| Array type     |    Test          |       Time  |
| -------------|--------------------------|-------|
| Indexed    |   set individual elements  | 1ms   |
| Indexed    |   get individual elements  | 1ms   |
| Indexed    |   get all elements    |      2ms   |
| Associative  | set individual elements  | 1ms   |
| Associative  | get individual elements  | 1ms   |
| Associative  | get all elements    |      2ms   |

100 elements array:

| Array type     |    Test          |       Time  |
| -------------|--------------------------|-------|
| Indexed    |   set individual elements  | 3ms   |
| Indexed    |   get individual elements  | 3ms   |
| Indexed    |   get all elements    |      3ms   |
| Associative  | set individual elements  | 2ms   |
| Associative  | get individual elements  | 3ms   |
| Associative  | get all elements    |      3ms   |

500 elements array:

| Array type     |    Test          |       Time  |
| -------------|--------------------------|-------|
| Indexed    |   set individual elements  | 11ms  |
| Indexed    |   get individual elements  | 7ms   |
| Indexed    |   get all elements    |      4ms   |
| Associative  | set individual elements  | 10ms  |
| Associative  | get individual elements  | 7ms   |
| Associative  | get all elements    |      4ms   |

1000 elements array:

| Array type     |    Test          |       Time  |
| -------------|--------------------------|-------|
| Indexed    |   set elements        |      18ms  |
| Indexed    |   get elements        |      14ms  |
| Indexed    |   get all elements    |      7ms   |
| Associative  | set individual elements  | 22ms  |
| Associative  | get individual elements  | 16ms  |
| Associative  | get all elements    |      7ms   |

5000 elements array:

| Array type     |    Test          |       Time  |
| -------------|--------------------------|-------|
| Indexed    |   set individual elements  | 135ms |
| Indexed    |   get individual elements  | 90ms  |
| Indexed    |   get all elements    |      80ms  |
| Associative  | set individual elements  | 200ms |
| Associative  | get individual elements  | 110ms |
| Associative  | get all elements    |      57ms  |

10000 elements array:

| Array type     |    Test          |       Time  |
| -------------|--------------------------|-------|
| Indexed    |   set individual elements  | 500ms |
| Indexed    |   get individual elements  | 200ms |
| Indexed    |   get all elements    |      320ms |
| Associative  | set individual elements  | 680ms |
| Associative  | get individual elements  | 280ms |
| Associative  | get all elements    |      160ms |

</details>

## Some more details
- The emulated arrays are stored in dynamically created variables. The base for the name of such variable is the same as the emulated array's name, except when creating the variable, the function prefixes it with `emu_[x]_`, where `[x]` stands for the type of the array: `a` for associative array, `i` for indexed array.
- For example, if calling a function to create an indexed array: `set_i_arr_el test_arr 5 "test_value"`, the function will create a variable called `emu_i_test_arr` and store the value in it.

## Test units
- The additional files (besides the `emulate-arrays.sh` script) are used for testing the main script. The test units are not very systematic but I tried to cover all points where the functionality may be fragile. To test in your environment, download all files into the same directory and then run the `emulate-arrays-tests.sh` script.
- To run a specific test set rather than all of them, comment the irrelevant lines in the `#### Main` section starting with `run_test_`
- To limit the test units executed, add arguments to the `run_test_` call, for example: `run_test_a_arr 5 8` will run test units from 5 through 8.
- Test units check for correct return codes, including in cases where an error is expected. So a significant portion of the tests intentionally induce errors in the functions. In order to avoid errors spam, by default STDERR output from the functions under test is silenced. If you want to see the errors anyway, uncomment the line `#print_stderr=true`.
- You can add your own test units following the same format. The test functions automatically parse the `.list` files and execute the tests inside, as long as they comply with the format.
