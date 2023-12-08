# POSIX-arrays
POSIX-compliant shell functions emulating functionality of arrays. The implementation mostly follows Bash arrays behavior.

## Usage
1) Source the script posix-arrays.sh in your script like so: `. [path]/posix-arrays.sh`
2) Call any function from the sourced script in your script.

Alternatively, copy some functions which you need to your own scripts. Most functions do not depend on each other.
Note that the last few lines in posix-arrays.sh set some variables. These variables need to be set for the functions to work correctly. If you want to use the functions without sourcing the script, you'll need to set them in your own script.

**Indexed arrays**:

`declare_i_arr <array_name> [value] [value] ... [value]` - Resets the array and assigns values to sequential elements, starting from index 0.

`read_i_arr <array_name> [string]` - Resets the array, then reads lines from from `[string]` and assigns each line as a value to sequential elements, starting from index 0.

`add_i_arr_el <array_name> <value>` - Adds a new element to the array and assigns a value to it. Index is set to previous highest index+1, or to 0 if no prior elements exist.

`set_i_arr_el <array_name> <index> [value]` - Assigns `[value]` to element with index `<index>`. Indices should always be nonnegative integer numbers. Indices don't have to be sequential. If `<value>` is an empty string, unsets the value.

`get_i_arr_val <array_name> <index> <var>` - Assigns value for `<index>` from the indexed array to variable `<var>`.

`get_i_arr_values <array_name> <var>` - Gets all values from an indexed array as a sorted (by index) whitespace-separated list and assigns the result to variable `<var>`.

`get_i_arr_indices <array_name> <var>` - Gets all indices from an indexed array as a sorted whitespace-separated list and assigns the result to variable `<var>`.

`unset_i_arr <array_name>` - Unsets all variables used to store the array in memory.

<details> <summary> Examples </summary>

```
set_i_arr_el test_arr 10 some_val
get_i_arr_val test_arr 10 test_var; echo "$test_var"
$ some_val
```

```
declare_i_arr test_arr val1 val2 "val3 123 etc"
get_i_arr_values test_arr test_var; echo "$test_var"
$ val1 val2 val3 123 etc

get_i_arr_val test_arr 2 test_var; echo "$test_var"
$ val3 123 etc
```

</details>

**Associative arrays**:

`declare_a_arr <array_name> [key=value] [key=value] ... [key=value]` - Resets the array and assigns values to keys.

`set_a_arr_el <array_name> <key>=[value]` - Assigns `[value]` to element with key `<key>`. If `[value]` is an empty string, stores empty string as a value.

`get_a_arr_val <array_name> <key> <var>` - Assigns value for `<key>` from the associative array to variable `<var>`.

`get_a_arr_values <array_name> <var>` - Gets all values as an alphabetically sorted (by key) whitespace-separated list and assigns the result to variable `<var>`.

`get_a_arr_keys <array_name> <var>` - Gets all keys as an alphabetically sorted whitespace-separated list and assigns the result to variable `<var>`.

`unset_a_arr <array_name>` - Unsets all variables used to store the array in memory.

<details> <summary> Examples </summary>

```
set_a_arr_el test_arr some_key="this is a test"
get_a_arr_val test_arr some_key test_var; echo "$test_var"

$ this is a test
```

```
declare_a_arr test_arr "cars=Audi, Honda, Mercedes" "music_genres=jazz, classical, rock"
get_a_arr_keys test_arr test_keys; echo "$test_keys"
$ cars music_genres

get_a_arr_val test_arr music_genres genres; echo "$genres"
$ jazz, classical, rock
```
</details>

## Details
- The arrays can hold strings that have any characters in them, including whitespaces and newlines.
- For indexed arrays, indices start at 0.
- As is default for shells, if you request a value corresponding to an index or to a key that has not been set previously, the functions will output an empty string and not return an error.
- Similarly, if you request a value from an array that has not been created, the functions output an empty string and not return an error.
- The indexed array effectively works as a sparse array, so indices do not have to be sequential.
- The declare functions are not necessary to create an array. It's just a way to set N elements in one command. Otherwise you can create an indexed array by simply calling the `set_i_arr_el()` function or an associative array by calling the `set_a_arr_el()` function.
- For indexed arrays, assigning en empty string as a value of an element unsets the element.
- For associative arrays, assigning an empty string as a value doesn't unset the array element. This mimics the behavior of Bash arrays. To unset an element of an associative array, use the `unset_a_arr_el()` function.
- The reason why functions provide output via a variable is because this way the performance is better, in some cases much better.

## Translation of Bash code examples
[TRANSLATION-EXAMPLES.md](/TRANSLATION-EXAMPLES.md)

## Performance
- The code went through multiple rounds of optimization. Currently for most use cases, the performance for small arrays (<= 200 elements) is comparable to Bash arrays. Functions perform reasonably well with arrays containing up to 2000 elements. Higher than that, the performance drops at an accelerating rate, mainly because the system takes longer to look up variables in memory.
- Performance is affected by the length of the strings stored in the array, and for associative arrays, by the length of the strings used as keys.
- Performance is also affected by the workload - more on that in the Limitations section.

<details> <summary> Benchmarks: </summary>

Measured on i7-4770 with 40-character strings in each element. For associative arrays, measured with 16-18 character keys.

**10 elements**:

| Array type   |      Test                    | Time  |
| -------------|------------------------------|-------|
| Indexed      | set elements one by one      | 1ms   |
| Indexed      | add elements one by one      | 1ms   |
| Indexed      | get values one by one        | 1ms   |
| Indexed      | get all values               | 1ms   |
| Indexed      | get all indices              | 2ms   |
| -------------|------------------------------|-------|
| Associative  | set elements one by one      | 1ms   |
| Associative  | get values one by one        | 1ms   |
| Associative  | get all values               | 1ms   |
| Associative  | get all keys                 | 2ms   |

**100 elements**:

| Array type   |      Test                    | Time  |
| -------------|------------------------------|-------|
| Indexed      | set elements one by one      | 3ms   |
| Indexed      | add elements one by one      | 3ms   |
| Indexed      | get values one by one        | 1ms   |
| Indexed      | get all values               | 1ms   |
| Indexed      | get all indices              | 3ms   |
| -------------|------------------------------|-------|
| Associative  | set elements one by one      | 3ms   |
| Associative  | get values one by one        | 3ms   |
| Associative  | get all values               | 2ms   |
| Associative  | get all keys                 | 3ms   |

**500 elements**:

| Array type   |      Test                    | Time  |
| -------------|------------------------------|-------|
| Indexed      | set elements one by one      | 11ms  |
| Indexed      | add elements one by one      | 8ms   |
| Indexed      | get values one by one        | 5ms   |
| Indexed      | get all values               | 4ms   |
| Indexed      | get all indices              | 4ms   |
| -------------|------------------------------|-------|
| Associative  | set elements one by one      | 13ms  |
| Associative  | get values one by one        | 10ms  |
| Associative  | get all values               | 4ms   |
| Associative  | get all keys                 | 4ms   |

**1000 elements**:

| Array type   |      Test                    | Time  |
| -------------|------------------------------|-------|
| Indexed      | set elements one by one      | 19ms  |
| Indexed      | add elements one by one      | 17ms  |
| Indexed      | get values one by one        | 8ms   |
| Indexed      | get all values               | 6ms   |
| Indexed      | get all indices              | 6ms   |
| -------------|------------------------------|-------|
| Associative  | set elements one by one      | 24ms  |
| Associative  | get values one by one        | 21ms  |
| Associative  | get all values               | 7ms   |
| Associative  | get all keys                 | 6ms   |

**2000 elements**:

| Array type   |      Test                    | Time  |
| -------------|------------------------------|-------|
| Indexed      | set elements one by one      | 39ms  |
| Indexed      | add elements one by one      | 37ms  |
| Indexed      | get values one by one        | 18ms  |
| Indexed      | get all values               | 13ms  |
| Indexed      | get all indices              | 13ms  |
| -------------|------------------------------|-------|
| Associative  | set elements one by one      | 57ms  |
| Associative  | get values one by one        | 41ms  |
| Associative  | get all values               | 14ms  |
| Associative  | get all keys                 | 14ms  |

</details>

## Limitations
- Functions which output all keys/indices or all values require a sorted list of keys/indices, and/or having all elements "verified", aka not having any registered keys/indices without an assigned value (which happens after unsetting an array element). However keeping a permanently verified and sorted array would be very slow if implemented in shell code. Therefore, sorting and verification of the array occurs when needed. These operations take some time, which may cause a temporary slowdown. Once the array is sorted, a flag is set so further queries are fast. Same applies to verification. The following actions may trigger the removal of one or both flags: setting a new index-value (or key-value) pair via the `set_[x]_arr_el` functions, unsetting a previously set value (via the same function) for indexed arrays, unsetting a previously set element (via the `unset_a_arr_el()` function) for associative arrays. Heuristics are implemented which identify cases where removal of the flags can be avoided.
- For small arrays, the functions should be fast enough regardless. Also the optimization heuristics cover most common use cases of indexed arrays, such as setting consecutive indexed array elements or changing values of existing elements. And some common use cases of associative arrays. So for the typical tasks, performance should be fine. For associative arrays, to avoid performance degradation caused by repeated sorting, group calls to the `set_a_arr_el()` function separately from calls to `get_a_arr_values()` and `get_a_arr_keys()` functions. For both types of arrays, to avoid performance degradation caused by repeated verification, group unsetting elements separately from calls to `get_[x]_arr_values()` and `get_[x]_arr_[keys/indices]()` functions.
- Array names and (for associative arrays) keys are limited to alphanumeric characters and underlines - `_`.

## Some more details
- The emulated arrays are stored in dynamically created variables. The name of such variable is in the format `___emu_[x]_[arr_name]_[key/index]`, where `[x]` stands for the type of the array: `a` for associative array, `i` for indexed array.
- For example, if calling a function to create an indexed array: `set_i_arr_el test_arr 5 "test_value"`, the function will create a variable called `___emu_i_test_arr_5` and store the value in it.
- This is the same for associative arrays, except `set_a_arr_el()` `declare_a_arr()` prepend ASCII code `\35` to the value when storing the variable. That is done to mark the key as set, even if assigning an empty value. This way, all set keys are always, which follows the convention of Bash associative arrays. Functions that retrieve values from associative arrays remove the ASCII prefix before assigning the result to the output variable.

## Test units
- The additional files (besides the `posix-arrays.sh` script) are used for testing the main script. The test units are not very systematic but I tried to cover all points where the functionality may be fragile. To test in your environment, download all files into the same directory and then run the `posix-arrays-tests.sh` script.
- To run a specific test set rather than all of them, comment the irrelevant lines in the `#### Main` section starting with `run_test_`
- To limit the test units executed, add arguments to the `run_test_` call, for example: `run_test_a_arr 5 8` will run test units from 5 through 8.
- Test units check for correct return codes, including in cases where an error is expected. So a significant portion of the tests intentionally induce errors in the functions. In order to avoid errors spam, by default STDERR output from the functions under test is silenced. If you want to see the errors anyway, uncomment the line `#print_stderr=true`.
- You can add your own test units following the same format. The test functions automatically parse the `.list` files and execute the tests inside, as long as they comply with the format.

## P.s.
If you like this project, please consider taking a second to give it a star. This will help other people to find it.
