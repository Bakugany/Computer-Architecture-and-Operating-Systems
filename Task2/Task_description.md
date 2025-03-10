# Division

Implement in assembly, callable from the C language, a function with the following declaration:

```c
int64_t mdiv(int64_t *x, size_t n, int64_t y);
```

The function performs integer division with remainder. It treats the dividend, divisor, quotient, and remainder as numbers represented in two's complement. The first and second parameters specify the dividend: `x` is a pointer to a non-empty array of `n` 64-bit integers. The dividend has 64 * n bits and is stored in memory in little-endian order. The third parameter, `y`, is the divisor. The result of the function is the remainder from the division of the dividend by `y`. The function places the quotient into the array `x`.

If the quotient cannot be stored in the array `x`, this indicates an overflow. A special overflow case is division by zero. The function should handle overflow in the same way as the `div` and `idiv` instructions, meaning that it should trigger interrupt number 0. In Linux, handling this interrupt involves sending the process the `SIGFPE` signal. The description of this signal as a "floating point exception" is somewhat misleading.

It may be assumed that the pointer `x` is valid and that `n` is a positive value.
