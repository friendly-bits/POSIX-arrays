# POSIX-arrays
POSIX-compliant shell functions emulating most aspects of arrays. The implementation mostly follows Bash arrays behavior.

## Usage
1) Source the script emulate-arrays.sh in your script like so: `. [path]/emulate-arrays.sh`
2) Call any function from the sourced script in your script.

Note that the last line in emulate-arrays.sh sets the delimiter variable. That variable needs to be set for the functions to work. If you want to use the functions without sourcing the script, you'll need to set that variable in your own script.

**Indexed arrays**:

`declare_i_arr <array_name> [value] [value] ... [value]` - Resets the array and assigns values to sequential elements, starting from index 0.

`read_i_arr <array_name> [string]` - Resets the array, then reads lines from from `[string]` and assigns each line as a value to sequential elements, starting from index 0.

`add_i_arr_el <array_name> <value>` - Adds a new element to the array and assigns a value to it. Index is set to previous highest index+1, or to 0 if no prior elements exist.

`set_i_arr_el <array_name> <index> [value]` - Assigns `[value]` to element with index `<index>`. Indices should always be nonnegative integer numbers. Indices don't have to be sequential. If `<value>` is an empty string, unsets the value.

`get_i_arr_el <array_name> <index> <var>` - Assigns value for `<index>` from the indexed array to variable `<var>`.

`get_i_arr_values <array_name> <var>` - Gets all values from an indexed array as a sorted (by index) whitespace-separated list and assigns the result to variable `<var>`.

`get_i_arr_indices <array_name> <var>` - Gets all indices from an indexed array as a sorted whitespace-separated list and assigns the result to variable `<var>`.

`clean_i_arr <array_name>` - Unsets all variables used to store the array in memory.

<details> <summary> Examples </summary>

```
set_i_arr_el test_arr 10 some_val
get_i_arr_el test_arr 10 test_var; echo "$test_var"
$ some_val
```

```
declare_i_arr test_arr val1 val2 "val3 123 etc"
get_i_arr_values test_arr test_var; echo "$test_var"
$ val1 val2 val3 123 etc

get_i_arr_el test_arr 2 test_var; echo "$test_var"
$ val3 123 etc
```

</details>

**Associative arrays**:

`declare_a_arr <array_name> [key=value] [key=value] ... [key=value]` - Resets the array and assigns values to keys.

`set_a_arr_el <array_name> <key>=[value]` - Assigns `[value]` to element with key `<key>`. If `[value]` is an empty string, stores empty string as a value.

`get_a_arr_el <array_name> <key> <var>` - Assigns value for `<key>` from the associative array to variable `<var>`.

`get_a_arr_values <array_name> <var>` - Gets all values as an alphabetically sorted (by key) whitespace-separated list and assigns the result to variable `<var>`.

`get_a_arr_keys <array_name> <var>` - Gets all keys as an alphabetically sorted whitespace-separated list and assigns the result to variable `<var>`.

`clean_a_arr <array_name>` - Unsets all variables used to store the array in memory.

<details> <summary> Example </summary>

```
set_a_arr_el test_arr some_key="this is a test"
get_a_arr_el test_arr some_key test_var; echo "$test_var"

$ this is a test
```

```
declare_a_arr test_arr "cars=Audi, Honda, Mercedes" "music_genres=jazz, classical, rock"
get_a_arr_keys test_arr test_keys; echo "$test_keys"
$ cars music_genres

get_a_arr_el test_arr music_genres genres; echo "$genres"
$ jazz, classical, rock
</details>

## Details
- The arrays can hold strings that have any characters in them, including whitespaces and newlines.
- Array names and (for associative arrays) keys are limited to alphanumeric characters and underlines - `_`.
- For indexed arrays, indices start at 0.
- As is default for shells, if you request a value corresponding to an index or to a key that has not been set previously, the functions will output an empty string and not return an error.
- The indexed array effectively works as a sparse array, so indices do not have to be sequential.
- The declare functions are not necessary to create an array. It's just a way to set N elements in one command. Otherwise you can create an indexed array by simply calling the `set_i_arr_el()` function or an associative array by calling the `set_a_arr_el()` function.
- The reason why functions provide output via a variable is because this way performance is better, and for some functions much better.

## Performance
- The code went through multiple rounds of optimization. Currently for most use cases, the performance for small arrays (<= 200 elements) is comparable to Bash arrays. Most functions perform reasonably well with arrays containing up to 2000 elements. Higher than that, the performance drops significanly.
- Performance is affected by the length of the strings stored in the array, and for associative arrays, by the length of the strings used as keys.
- Performance is also affected by the way the functions are being used. Some functions require having a sorted list of keys and values. However keeping a constantly updated list would be very slow if implemented in shell code. Therefore, sorting of the array occurs as needed. Once the array is scanned and sorted, a flag is set so further queries are fast. Setting a new index-value (or key-value) pair triggers the removal of the flag, so sorting will occur next time when needed. Functions that require a sorted array are `get_[x]_arr_[values/indices/keys]` and `add-i-arr-el`. The removal of the sorted flag is triggered when `set-[x]-arr-el` functions are called. The `declare_[x]_arr` functions reset the array and set the sorted flag before exiting.
- Hence, the most efficient way to use the functions is by grouping calls to the `set_[x]_arr_el` functions separately from calls to other functions and avoiding mixing calls to former with calls to latter.
- That said, for small arrays the functions should be fast enough regardless.
- While the code works if run under Bash and probably any other Unix-compatible shell, it runs much faster in a simpler shell like Dash. In my comparison it was about 3x faster under Dash compared to Bash.

<details> <summary> Benchmarks: </summary>

Measured on i7-4770 with 40-character strings in each element. For associative arrays, measured with 16-18 character keys.

**10 elements**:

| Array type   |      Test                    | Time  |
| -------------|------------------------------|-------|
| Indexed      | set elements one by one      | 1ms   |
| Indexed      | add elements one by one      | 2ms   |
| Indexed      | get elements one by one      | 1ms   |
| Indexed      | get all values               | 1ms   |
| Indexed      | get all indices              | 2ms   |
| -------------|------------------------------|-------|
| Associative  | set elements one by one      | 1ms   |
| Associative  | get elements one by one      | 1ms   |
| Associative  | get all values               | 1ms   |
| Associative  | get all keys                 | 2ms   |

**100 elements**:

| Array type   |      Test                    | Time  |
| -------------|------------------------------|-------|
| Indexed      | set elements one by one      | 3ms   |
| Indexed      | add elements one by one      | 4ms   |
| Indexed      | get elements one by one      | 3ms   |
| Indexed      | get all values               | 1ms   |
| Indexed      | get all indices              | 3ms   |
| -------------|------------------------------|-------|
| Associative  | set elements one by one      | 3ms   |
| Associative  | get elements one by one      | 3ms   |
| Associative  | get all values               | 2ms   |
| Associative  | get all keys                 | 3ms   |

**500 elements**:

| Array type   |      Test                    | Time  |
| -------------|------------------------------|-------|
| Indexed      | set elements one by one      | 11ms  |
| Indexed      | add elements one by one      | 12ms  |
| Indexed      | get elements one by one      | 10ms  |
| Indexed      | get all values               | 3ms   |
| Indexed      | get all indices              | 4ms   |
| -------------|------------------------------|-------|
| Associative  | set elements one by one      | 13ms  |
| Associative  | get elements one by one      | 10ms  |
| Associative  | get all values               | 4ms   |
| Associative  | get all keys                 | 4ms   |

**1000 elements**:

| Array type   |      Test                    | Time  |
| -------------|------------------------------|-------|
| Indexed      | set elements one by one      | 19ms  |
| Indexed      | add elements one by one      | 20ms  |
| Indexed      | get elements one by one      | 18ms  |
| Indexed      | get all values               | 6ms   |
| Indexed      | get all indices              | 6ms   |
| -------------|------------------------------|-------|
| Associative  | set elements one by one      | 24ms  |
| Associative  | get elements one by one      | 21ms  |
| Associative  | get all values               | 7ms   |
| Associative  | get all keys                 | 6ms   |

**2000 elements**:

| Array type   |      Test                    | Time  |
| -------------|------------------------------|-------|
| Indexed      | set elements one by one      | 39ms  |
| Indexed      | add elements one by one      | 54ms  |
| Indexed      | get elements one by one      | 38ms  |
| Indexed      | get all values               | 13ms  |
| Indexed      | get all indices              | 13ms  |
| -------------|------------------------------|-------|
| Associative  | set elements one by one      | 57ms  |
| Associative  | get elements one by one      | 41ms  |
| Associative  | get all values               | 14ms  |
| Associative  | get all keys                 | 14ms  |

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
