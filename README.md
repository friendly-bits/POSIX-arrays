# POSIX-arrays
POSIX-compliant shell functions emulating some aspects of arrays

## Usage
1) Source the script emulate-arrays.sh in your script like so: `. [path]/emulate-arrays.sh`
2) Call any function from the sourced script in your script.

Note that the last line in emulate-arrays.sh sets the delimiter variable. That variable needs to be set for the functions to work. If you want to use the functions without sourcing the script, you'll need to set that variable in your own script.

**Indexed arrays**:

`declare_i_arr <array_name> [value] [value] ... [value]` - resets the array and assigns values to sequential indices, starting from 0

`set_i_arr_el <array_name> <index> [value]` - assigns `[value]` to `<index>`. indices should always be positive integer numbers. This acts as a sparse array, so indices don't have to be sequential.

`get_i_arr_el <array_name> <index>` - reads value for `<index>` from the indexed array

`get_i_arr_all <array_name>` - reads all values from the indexed array and outputs a sorted (by index) whitespace-separated list

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

`set_a_arr_el <array_name> <key>=[value]`

`get_a_arr_el <array_name> <key>`

**Example**:

Input:

```
set_a_arr_el test_arr some_key="this is a test"
get_a_arr_el test_arr some_key
```

Output: `this is a test`

## More details
- The emulated arrays are stored in dynamically created variables. The base for the name of such variable is the same as the emulated array's name, except when creating the variable, the function prefixes it with `emu_[x]_`, where [x] stands for type of the array: a for associative array, i for indexed array.
- For example, if calling a function to create an indexed array: `set_i_arr_el test_arr 5 "test_value"`, the function will create a variable called `emu_i_test_arr` and store the value in it.
- The delimiter used internally is ASCII code \37 (octal). It's an escape code defined as "unit separator". That definition doesn't really matter. What matters is that this code doesn't correspond to any "normal" character. This way arrays can hold strings that have any "normal" delimiter in them, including whitespaces and newlines. The only downside is that if you try to directly access the variable holding the emulated array, you probably will not get a normally-looking value out of it, since the ASCII escape code will mess it up.
- Functions check for correct number of arguments and return an error if it's incorrect.
- The indexed array functions check the index to make sure it's a nonnegative integer, and return an error otherwise.
- The indices start at 0
- As is default for shells, if you request a value corresponding to an index or to a key that has not been set previously, the functions will output an empty string and not return an error.
- The indexed array effectively works as a sparse array, meaning that the indices do not have to be sequential. For example, you can set a value for index 10 and for index 100 while all other indices will not be set.
- The declare function for the indexed array is not necessary to create an array. It's just a way to set N values sequentially in one command. Otherwise you can create an indexed array by simply calling the `set_i_arr_el()` function.
- Similarly, you can create an associative array by calling the `set_a_arr_el()` function.
- The code is as efficient as I could make it, only using the shell built-ins (except for get-i-arr-all() function where I used the `sort` utility for sorting). However, it's still shell code which performance-wise can't compete with native implementation of arrays. Should be fine for lightweight arrays use.
