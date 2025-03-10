# NAND Gates

The task consists of implementing, in the C language, a dynamically loaded library that handles combinational Boolean circuits composed of NAND gates. A NAND gate has a nonnegative integer number of inputs and one output. A NAND gate with no inputs always produces a false signal at its output. A NAND gate with one input acts as a negation. For a positive *n*, the *n*-input gate’s inputs are numbered from 0 to *n* - 1. Each input may receive a Boolean signal that takes the value `false` or `true`. The output of the gate yields `false` if all of its inputs are `true`, and `true` otherwise. The signal from a gate’s output can be connected to multiple gate inputs. However, only one signal source can be connected to a given gate input.

## Library Interface

The interface to the library is provided in the file `nand.h` attached to the assignment statement, which contains the declarations below. Additional details regarding the operation of the library should be inferred from the file `nand_example.c` attached to the assignment statement, which is an integral part of the specification.

```c
typedef struct nand nand_t;
```

This is the name of the structural type representing a NAND gate. You must define (implement) this type as part of this assignment.

### nand_new

```c
nand_t * nand_new(unsigned n);
```

The function `nand_new` creates a new NAND gate with *n* inputs. The result of the function is:

- A pointer to the structure representing the NAND gate;
- `NULL` – if a memory allocation error occurs; in that case, the function sets `errno` to `ENOMEM`.

### nand_delete

```c
void nand_delete(nand_t *g);
```

The function `nand_delete` disconnects both the input and output signals of the specified gate, then frees the gate along with all memory used by it. It does nothing if called with a `NULL` pointer. After this function is executed, the pointer passed to it becomes invalid.

*Parameter:*
- `g` – pointer to the structure representing the NAND gate.

### nand_connect_nand

```c
int nand_connect_nand(nand_t *g_out, nand_t *g_in, unsigned k);
```

The function `nand_connect_nand` connects the output of gate `g_out` to input number *k* of gate `g_in`, possibly disconnecting an existing signal that was connected to that input.

*Parameters:*
- `g_out` – pointer to the structure representing the NAND gate;
- `g_in` – pointer to the structure representing the NAND gate;
- `k` – the number of the input of gate `g_in`.

*Return value:*
- `0` – if the operation was successful;
- `-1` – if either pointer is `NULL`, the parameter *k* is invalid, or a memory allocation error occurred; in this case, the function sets `errno` appropriately to `EINVAL` or `ENOMEM`.

### nand_connect_signal

```c
int nand_connect_signal(bool const *s, nand_t *g, unsigned k);
```

The function `nand_connect_signal` connects the Boolean signal `s` to input number *k* of gate `g`, possibly disconnecting an existing signal that was previously connected to that input.

*Parameters:*
- `s` – pointer to a `bool` variable;
- `g` – pointer to the structure representing the NAND gate;
- `k` – the number of the input of gate `g`.

*Return value:*
- `0` – if the operation was successful;
- `-1` – if any pointer is `NULL`, the parameter *k* is invalid, or a memory allocation error occurred; in this case, the function sets `errno` appropriately to `EINVAL` or `ENOMEM`.

### nand_evaluate

```c
ssize_t nand_evaluate(nand_t **g, bool *s, size_t m);
```

The function `nand_evaluate` computes the Boolean signals on the outputs of the given gates and calculates the length of the critical path.

For a Boolean signal or for a gate with no inputs, the critical path length is zero. The critical path length at the output of a gate is given by:

  1 + max(S0, S1, S2, …, Sn−1)

where *Si* is the critical path length of its *i*-th input. The critical path length for the entire circuit is the maximum of the critical path lengths at the outputs of all the provided gates.

*Parameters:*
- `g` – pointer to an array of pointers to structures representing NAND gates;
- `s` – pointer to an array in which the computed output values will be placed;
- `m` – the size of the arrays pointed to by `g` and `s`.

*Return value:*
- The length of the critical path, if the operation was successful; in that case, the array `s` contains the computed output values of the gates, where `s[i]` holds the value at the output of the gate pointed to by `g[i]`;
- `-1` – if any pointer is `NULL`, *m* is zero, the operation failed, or memory allocation was unsuccessful; in this case, the function sets `errno` appropriately to `EINVAL`, `ECANCELED`, or `ENOMEM`, and the contents of the array `s` are undefined.

### nand_fan_out

```c
ssize_t nand_fan_out(nand_t const *g);
```

The function `nand_fan_out` determines the number of gate inputs that are connected to the output of the given gate.

*Parameter:*
- `g` – pointer to the structure representing the NAND gate.

*Return value:*
- The number of gate inputs connected to the output of the given gate, if the operation was successful;
- `-1` – if the pointer is `NULL`; in this case, the function sets `errno` to `EINVAL`.

### nand_input

```c
void* nand_input(nand_t const *g, unsigned k);
```

The function `nand_input` returns a pointer to the Boolean signal or gate that is connected to input number *k* of the gate pointed to by `g`, or `NULL` if nothing is connected to that input.

*Parameters:*
- `g` – pointer to the structure representing the NAND gate;
- `k` – the number of the input.

*Return value:*
- A pointer of type `bool*` or `nand_t*`;
- `NULL` – if nothing is connected to the specified input; in this case, the function sets `errno` to 0;
- `NULL` – if the pointer `g` is `NULL` or if the value of *k* is invalid; in this case, the function sets `errno` to `EINVAL`.

### nand_output

```c
nand_t* nand_output(nand_t const *g, ssize_t k);
```

The function `nand_output` allows iteration over the gates connected to the output of the specified gate. The result of this function is undefined if its parameters are invalid. If the output of gate `g` is connected to multiple inputs of the same gate, that gate appears multiple times in the iteration result.

*Parameters:*
- `g` – pointer to the structure representing the NAND gate;
- `k` – an index in the range from zero to one less than the value returned by `nand_fan_out`.

*Return value:*
- A pointer of type `nand_t*` to the gate connected to the output of gate `g`.
