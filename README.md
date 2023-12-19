# POSIX-arrays
POSIX-compliant shell functions emulating functionality of arrays. The implementation mostly follows Bash arrays behavior.

## Usage
1) Source the script posix-arrays.sh in your script like so: `. [path]/posix-arrays.sh`
2) Call any function from the sourced script in your script.

Alternatively, copy functions which you need (and their dependencies) to your own scripts. Note that the last few lines in posix-arrays.sh set some variables. These variables need to be set for the functions to work correctly.

### **Indexed arrays**:

#### Initializing an array and setting elements:

`init_i_arr <array_name> <N> <val>` - Resets the array and assigns value `<val>` to `<N>` first elements, starting with index 0. If `<val>` is an empty string, assigns empty strings.

`declare_i_arr <array_name> [value] [value] ... [value]` - Resets the array and assigns values to sequential elements, starting from index 0.

`read_i_arr <array_name> [string]` - Resets the array, then reads lines from `[string]` and assigns each line as a value to sequential elements, starting from index 0.

`add_i_arr_el <array_name> <value>` - Adds a new element to the array and assigns a value to it. Index is set to previous highest index+1, or to 0 if no prior elements exist.

`set_i_arr_el <array_name> <index> [value]` - Assigns `[value]` to element with index `<index>`. Indices should always be nonnegative integer numbers. Indices don't have to be sequential. If `<value>` is an empty string, stores empty string as a value.

`unset_i_arr_el <array_name> <index>` - Unsets the element with index `<index>`.

#### Getting array values, indices and parameters:

`get_i_arr_val <array_name> <index> <var>` - Assigns value for `<index>` to variable `<var>`.

`get_i_arr_values [-s] <array_name> <var>` - Gets all values from an indexed array as a whitespace-separated list and assigns the result to variable `<var>`. When called with the `[-s]` option, sorts the indices and outputs a numerically sorted (by index) list of values.

`get_i_arr_indices [-s] <array_name> <var>` - Gets all indices from an indexed array as a whitespace-separated list and assigns the result to variable `<var>`. When called with the `[-s]` option, sorts the indices and outputs a numerically sorted list.

`get_i_arr_el_cnt <array_name> <var>` - Gets elements count of an indexed array and assigns the result to variable `<var>`.

`get_i_arr_max_index <array_name> <var>` - Gets the currently highest index in the array and assigns it to variable `<var>`. Returns an error if the array is empty or doesn't exist.

`get_i_arr_last_val <array_name> <var>` - Gets the value assigned to highest index in the array and assigns it to variable `<var>`. Returns an error if the array is empty or doesn't exist.

#### Sorting an array
`sort_i_arr <array_name>` - Sorts indices stored in the array. Sorting is a relatively slow operation. Functions keep track of sorted/unsorted state of the array via a flag and will only perform sorting if current state is unsorted. For indexed arrays, optimizations are implemented which allow the array to keep the sorted state in most (but not all) cases when setting elements. Specifically, the 'sorted' flag will be removed if setting a previously unset element with a lower index than the current max index of the array. Unsetting elements doesn't affect the sorted/unsorted state of the array.

#### Unsetting an array

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

### **Associative arrays**:

#### Declaring an array and setting elements:

`declare_a_arr <array_name> [key=value] [key=value] ... [key=value]` - Resets the array and assigns values to keys.

`set_a_arr_el <array_name> <key>=[value]` - Assigns `[value]` to element with key `<key>`. If `[value]` is an empty string, stores empty string as a value.

`unset_a_arr_el <array_name> <key>` - Unsets the element with key `<key>`.

#### Getting array keys, values and parameters

`get_a_arr_val <array_name> <key> <var>` - Assigns value for `<key>` from the associative array to variable `<var>`.

`get_a_arr_values [-s] <array_name> <var>` - Gets all values as a whitespace-separated list and assigns the result to variable `<var>`. When called with the `[-s]` option, sorts the keys and outputs an alphabetically sorted (by key) list of values.

`get_a_arr_keys [-s] <array_name> <var>` - Gets all keys as a whitespace-separated list and assigns the result to variable `<var>`. When called with the `[-s]` option, sorts the keys and outputs an alphabetically sorted list.

`get_a_arr_el_cnt <array_name> <var>` - Gets elements count of an associative array and assigns the result to variable `<var>`.

#### Sorting an array
`sort_a_arr <array_name>` - Sorts keys stored in the array. Sorting is a relatively slow operation. Functions keep track of sorted/unsorted state of the array via a flag and will only perform sorting if current state is unsorted. For associative arrays, an optimization is implemented which allows the array to keep the sorted state in some (but not all) cases when setting elements. Specifically, when changing a value of a previously set element, the sorted state of the array is kept if it was sorted before. Setting a new element removes the flag which marks the array as sorted. Unsetting elements doesn't affect the sorted/unsorted state of the array.

#### Unsetting an array

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
- The arrays can hold strings that have any characters in them, including whitespaces, single and double quotation marks and newlines.
- For indexed arrays, indices start at 0.
- As is default for shells, if you request a value corresponding to an index or to a key that has not been set previously, the functions output an empty string and do not return an error.
- Similarly, if you request a value from an array that has not been created, the functions output an empty string and do not return an error.
- The indexed array effectively works as a sparse array, so indices do not have to be sequential.
- The initialize and declare functions are not necessary to create an array. It's just a way to set N elements in one command. You can create an array by calling any function that stores a value in the array.
- Assigning an empty string as a value doesn't unset the array element. This mimics the behavior of Bash arrays. To unset an element, use the `unset_[x]_arr_el()` functions.
- Functions provide output via a variable because this way the performance is better, in some cases much better.

## Examples of translation from Bash syntax to POSIX-arrays syntax
[BASH-TRANSLATION-EXAMPLES.md](/BASH-TRANSLATION-EXAMPLES.md)

## Performance
- The code went through multiple rounds of optimization. Currently for most use cases, on x86 CPU the performance for small arrays (<= 200 elements) is comparable to Bash arrays. Functions perform reasonably well with arrays containing up to 2000 elements. Higher than that, the performance drops at an accelerating rate, mainly because the system takes longer to look up variables in memory.
- Performance is affected by the length of the strings stored in the array, and for associative arrays, by the length of the strings used as keys.
- Performance is also affected by the workload - more on that in the [Limitations](#limitations) section.

<details> <summary> Benchmarks: </summary>

Measured on i7-4770 with 40-character strings in each element. For associative arrays, measured with 16-18 character keys. N is the number of elements.

**N=10:**

| Array type   |      Test                            | Time  |
| -------------|--------------------------------------|-------|
| Indexed      | set N elements one by one (cold*)    | 1ms   |
| Indexed      | set N elements one by one (hot**)    | 1ms   |
| Indexed      | add N elements one by one            | 2ms   |
| Indexed      | get N values one by one              | 1ms   |
| Indexed      | get all values                       | 2ms   |
| Indexed      | get all indices                      | 1ms   |
| Indexed      | unset N elements one by one          | 1ms   |
| -------------|--------------------------------------|-------|
| Associative  | set N elements one by one (cold*)    | 1ms   |
| Associative  | set N elements one by one (hot**)    | 1ms   |
| Associative  | get N values one by one              | 1ms   |
| Associative  | get all values                       | 1ms   |
| Associative  | get all keys                         | 1ms   |
| Associative  | unset N elements one by one          | 1ms   |

**N=100**:

| Array type   |      Test                            | Time  |
| -------------|--------------------------------------|-------|
| Indexed      | set N elements one by one (cold*)    | 4ms   |
| Indexed      | set N elements one by one (hot**)    | 2ms   |
| Indexed      | add N elements one by one            | 2ms   |
| Indexed      | get N values one by one              | 2ms   |
| Indexed      | get all values                       | 2ms   |
| Indexed      | get all indices                      | 2ms   |
| Indexed      | unset N elements one by one          | 4ms   |
| -------------|--------------------------------------|-------|
| Associative  | set N elements one by one (cold*)    | 4ms   |
| Associative  | set N elements one by one (hot**)    | 2ms   |
| Associative  | get N values one by one              | 2ms   |
| Associative  | get all values                       | 2ms   |
| Associative  | get all keys                         | 1ms   |
| Associative  | unset N elements one by one          | 4ms   |

**N=1000**:

| Array type   |      Test                            | Time  |
| -------------|--------------------------------------|-------|
| Indexed      | set N elements one by one (cold*)    | 22ms  |
| Indexed      | set N elements one by one (hot**)    | 10ms  |
| Indexed      | add N elements one by one            | 11ms  |
| Indexed      | get N values one by one              | 6ms   |
| Indexed      | get all values                       | 6ms   |
| Indexed      | get all indices                      | 1ms   |
| Indexed      | unset N elements one by one          | 23ms  |
| -------------|--------------------------------------|-------|
| Associative  | set N elements one by one (cold*)    | 24ms  |
| Associative  | set N elements one by one (hot**)    | 11ms  |
| Associative  | get N values one by one              | 7ms   |
| Associative  | get all values                       | 6ms   |
| Associative  | get all keys                         | 1ms   |
| Associative  | unset N elements one by one          | 35ms  |

**N=2000**:

| Array type   |      Test                            | Time  |
| -------------|--------------------------------------|-------|
| Indexed      | set N elements one by one (cold*)    | 40ms  |
| Indexed      | set N elements one by one (hot**)    | 20ms  |
| Indexed      | add N elements one by one            | 24ms  |
| Indexed      | get N values one by one              | 16ms  |
| Indexed      | get all values                       | 15ms  |
| Indexed      | get all indices                      | 1ms   |
| Indexed      | unset N elements one by one          | 48ms  |
| -------------|--------------------------------------|-------|
| Associative  | set N elements one by one (cold*)    | 56ms  |
| Associative  | set N elements one by one (hot**)    | 22ms  |
| Associative  | get N values one by one              | 18ms  |
| Associative  | get all values                       | 15ms  |
| Associative  | get all keys                         | 2ms   |
| Associative  | unset N elements one by one          | 101ms |

\* cold - elements are set without prior initialization

** hot - elements are set after prior initialization

</details>

## Limitations
- Unsetting individual elements is relatively slow because it requires to process all current indices/keys in the array as a string. To work around this, when possible, assign an empty string as a value to the element instead of unsetting the element. Alternatively, if you want to free up the memory used by the array, use the `unset_[x]_arr()` functions which work hundreds of times faster than unsetting individual elements. Optimizations have been implemented which cover unsetting elements sequentially from the 1st one upwards or from the last one downwards (in the order in which the elements are stored), so under these conditions unsetting elements does not incur a large performance hit.
- By default, functions that output all indices/keys/values do not sort the output. This is different from Bash arrays behavior which sorts the output. The reason for this is that sorting is relatively slow and in most cases not required. When sorted output is required, use the functions with the `-s` option to get a sorted (by index/key) output. Once sorting occurs, the array will stay sorted until new elements are set. In some cases, the functions are able to maintain the sorted state when setting elements and in other cases not, as described in the `Sorting an array` sections above. Unsetting elements doesn't affect the sorted/unsorted state of arrays. An optimization has been implemented which buffers unsorted keys/indices. This minimizes performance hit for workloads which require sorting.
- For indexed arrays, the `get_i_arr_max_index()` and `get_i_arr_last_value()` functions require the array to be sorted and hence when called, sorting of the array will occur. Which, as mentioned above, is relatively slow.
- Array names and (for associative arrays) keys are limited to English alphanumeric characters and underlines - `_`.
- Functions have been tested exclusively with the `POSIX` (or `C`) locale and are likely to misbehave in some other locales. This may manifest in functions complaining about invalid array names or keys, or incorrect sorting, or even the unset functions working incorrectly. To avoid such issues, the `posix-arrays.sh` script exports the `LC_ALL` variable. Note that sourcing this script will change the locale to C in the current shell the script is running in and its subshells (this won't stick when the script exits).

## Some more details
- The values are stored in dynamically created variables. The name of such variable is in the format `_[x]_[arr_name]_[key/index]`, where `[x]` stands for the type of the array: `a` for associative array, `i` for indexed array.
- For example, if calling a function to create an indexed array: `set_i_arr_el test_arr 5 "test_value"`, the function will create a variable called `_i_test_arr_5` and store the value in it.
- The raw values stored in the variables have an ASCII code `\35` prepended to the "logical" value. This serves as a flag to mark the element as set. This way, an empty string can be assigned as a value to an element. This follows the convention of Bash arrays. Functions which retrieve values from the arrays remove the ASCII prefix before assigning the result to the output variable.

## Test units
- The additional files (besides the `posix-arrays.sh` script) are used for testing the main script. The test units are not very systematic but I tried to cover all points where the functionality may be fragile. To test in your environment, download all files into the same directory and then run the `posix-arrays-tests.sh` script.
- To run a specific test set rather than all of them, comment the irrelevant lines in the `#### Main` section starting with `run_test_`
- To limit the test units executed, add arguments to the `run_test_` call, for example: `run_test_a_arr 5 8` will run test units from 5 through 8.
- Test units check for correct return codes, including in cases where an error is expected. So a significant portion of the tests intentionally induce errors in the functions. In order to avoid errors spam, by default STDERR output from the functions under test is silenced. If you want to see the errors anyway, uncomment the line `#print_stderr=true`.
- You can add your own test units following the same format. The test functions automatically parse the `.list` files and execute the tests inside, as long as they comply with the format.

## P.s.
If you like this project, please consider taking a second to give it a star. This will help other people to find it.
