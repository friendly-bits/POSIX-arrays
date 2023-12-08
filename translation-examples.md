# Indexed arrays

### Declaring an array, assigning and adding values
Bash code:
```
declare test_arr=(a b c)
test_arr[100]="this is a test"
test_arr+=("this is another test")
test_arr[101]=""
```
POSIX-arrays code:
```
declare_i_arr test_arr a b c
set_i_arr_el test_arr 100 "this is a test"
add_i_arr_el test_arr "this is another test"
set_i_arr_el test_arr 101 ""
```

### Getting values and indices and working with loops
Bash code:
```
declare test_arr=("no_whitespaces_value1" "no_whitespaces_value2")
for value in ${test_arr[@]}; do
    echo "$value"
done
```
POSIX-arrays code:
```
declare_i_arr test_arr "no_whitespaces_value1" "no_whitespaces_value2"
get_i_arr_values test_arr values
for value in $values; do
    echo "$value"
done
```

Bash code:
```
for index in ${!test_arr[@]}; do
    echo "$index"
done
```
POSIX-arrays code:
```
get_i_arr_indices test_arr indices
for index in $indices; do
    echo "$index"
done
```

Bash code:
```
declare test_arr=("i_don't_have_whitespaces" "i have whitespaces")
for value in ${test_arr[@]}; do
    echo "$value"
done
```
POSIX-arrays code (here we need to loop through indices rather than through values, to avoid whitespace issues):
```
declare_i_arr test_arr 1 10 100
get_i_arr_indices test_arr indices
for index in $indices; do
    get_i_arr_val "$index" value
    echo "$value"
done
```

## Associative arrays

### Declaring an array, assigning and adding values
Bash code:
```
declare -A test_arr
test_arr[key]="test_val"
echo "value for 'key': '${test_arr[key]}'"
unset test_arr[key]
```
POSIX-arrays code:
```
set_a_arr_el test_arr key="test_val"
get_a_arr_val test_arr value
echo "value for 'key': '$value'"
unset_a_arr_el test_arr key
```

Bash code:
```
test_arr[test_key]="this is a test"
test_arr+=([test_key2]="this is another test")
unset test_arr[test_key2]
```
POSIX-arrays-code:
```
set_a_arr_el test_arr test_key "this is a test"
set_a_arr_el test_arr test_key2 "this is another test"
unset_a_arr_el test_arr test_key2
```

### Getting values and indices and working with loops

Bash code:
```
for value in ${test_arr[@]}; do
    echo "$value"
done
unset test_arr
```
POSIX-arrays code:
```
get_a_arr_values test_arr values
for value in $values; do
    echo "$value"
done
unset_a_arr test_arr
```

Bash code:
```
for key in ${!test_arr[@]}; do
    echo "$key"
done
```
POSIX-arrays code:
```
get_a_arr_keys test_arr keys
for key in $keys; do
    echo "$key"
done
```
