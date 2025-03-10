# Files with Holes

In Linux, files can be "holey". For the purposes of this assignment, we assume that a file with holes consists of contiguous fragments. At the beginning of each fragment there is a two-byte length (in bytes) indicating the size of the data in that fragment. This is followed by the data. The fragment ends with a four-byte offset, which specifies by how many bytes you need to move from the end of the current fragment to the beginning of the next fragment. The length of the data in the block is a 16-bit number in natural binary representation. The offset is a 32-bit number in two's complement representation. Numbers in the file are stored in little-endian order. The first fragment starts at the beginning of the file. The last fragment is recognized by the fact that its offset points to itself. Fragments in the file may touch or even overlap.

## File Checksum

The file checksum is calculated using a cyclic redundancy check (CRC), taking into account the data from the successive fragments of the file. The file data is processed byte by byte. It is assumed that the most significant bit of a data byte and of the CRC polynomial (divisor) is written on the left-hand side.

## Task

Implement, in assembly, a program `crc` that computes the checksum of the data contained in a specified file with holes. The program is invoked as follows:

```
./crc file crc_poly
```

- The parameter `file` is the name of the file.
- The parameter `crc_poly` is a string of `0`s and `1`s that describe the CRC polynomial. The coefficient corresponding to the highest degree term is omitted. The maximum degree of the CRC polynomial is 64 (i.e., the maximum length of the CRC divisor is 65). For example, the string `11010101` represents the polynomial: x⁸ + x⁷ + x⁶ + x⁴ + x² + 1.

A constant polynomial is considered invalid.

The program prints the computed checksum to standard output as a string consisting of `0`s and `1`s, terminated by a newline character (`\n`). The program should signal a successful termination with exit code 0.

## System Calls

The program should use Linux system calls:

- `sys_open`
- `sys_read`
- `sys_write`
- `sys_lseek`
- `sys_close`
- `sys_exit`

The program must check the validity of parameters and the return values of the system calls (except for `sys_exit`). If any parameter is invalid or a system call fails, the program should terminate with exit code 1. In every case, the program must explicitly call `sys_close` for any file that was opened before exiting.

## Buffered Reading

To achieve satisfactory performance, the program should read data using buffering. You should select an optimal buffer size and include a comment in your code indicating the chosen size and the rationale behind it.
