global _start

SYS_READ    equ 0
STD_OUT     equ 1
SEEK_CUR    equ 1
SYS_WRITE   equ 1
SYS_OPEN    equ 2
SYS_CLOSE   equ 3
SYS_LSEEK   equ 8
SYS_EXIT    equ 60
PRINT_SIZE  equ 64
BUFFER_SIZE equ 68000
END_LINE    equ 0x0a

section .bss
    buffer: resb BUFFER_SIZE
    buffer_print: resb PRINT_SIZE
section .text
                        ; r8 - crc polynomial length
                        ; r9 - crc polynomial
                        ; r10 - file descriptor
_start:

; We check if user gave appropriate number of arguments of function, if not we finish.
    mov rcx, [rsp]
    cmp rcx, 3
    jnz .end

; We transform crc polynomial from string to integer.
    mov rsi, [rsp + 24]
    xor rdx, rdx
    xor rcx, rcx
    xor rax, rax

.read_polynomial:
    lodsb
    test rax, rax          ; If rax register is 0 that means that it's the end of polynomial.
    jz .end_of_polynomial

; If character is different than '0' oraz '1' input is invalid.
    cmp rax, '0'
    jb .end
    cmp rax, '1'
    ja .end

    sub rax, '0'
    shl rdx, 1
    add rdx, rax
    inc rcx
jmp .read_polynomial

.end_of_polynomial:

; If crc polynomial has length 0 (it's constanst) input is invalid.
    cmp rcx, 0
    je .end

; If crc polynomials is longer than 64 characters input is invalid.
    cmp rcx, 64
    ja .end

    mov r8, rcx
    mov r9, rdx
    cmp r8, 64
    jb .add_zeros

; We shift crc polynomial to make it's most significant bits go to the left.
.add_zeros:
    neg cl
    add cl, 64
    shl r9, cl

; We try to open file (if it wasn't succesful we end) otherwise we put descriptor of file to r10.
    mov rax, SYS_OPEN
    mov rdi, [rsp + 16]
    mov rdx, 0
    mov rsi, 0
    syscall
    cmp rax, 0
    jl .end
    mov r10, rax

; Now we read from the file and calculate crc
                        ; r12 how many bytes yet to read.
                        ; r13 position in bufor.
                        ; r14 length of segment 
                        ; r15 result
    xor r15, r15
.read_from_the_file:

; First we read the length of the segment.
    mov r12, 2
    lea r13, [buffer]

; Readings are in loops because SYS_READ can read less than what we expect (however it cannot read 0, unless it's end od file).
.read_the_length_of_segment:
    mov rax, SYS_READ
    mov rdi, r10        ; Move file desciptor to rdi.
    mov rsi, r13        ; Move buffer to rsi.
    mov rdx, r12        ; Move number of bytes to rdx.
    syscall 
    cmp rax, 0          ; If it read 0 bites we end.
    jl .close_the_file
    add r13, rax        ; We move buffer.
    sub r12, rax        ; We substract number of bytes read from r12.
    cmp r12, 0
    ja .read_the_length_of_segment

    mov rsi, buffer     ; We move pointer to the buffer to rsi.
    lodsw
    mov r14, rax        ; We move length of segment to r14.
    add r14, 6          ; We add length of offset and bytes that give length of segment.
    mov r12, rax        ; We move length of segment to r12.
    mov r13, buffer

    cmp r12, 0          ; If segment is empty we cannot read from it.
    je .segment_was_empty 
    
.read_the_segment:
    mov rax, SYS_READ
    mov rdi, r10
    mov rsi, r13
    mov rdx, r12
    syscall
    cmp rax, 0
    jle .close_the_file
    sub r12, rax
    add r13, rax
    cmp r12, 0
    ja .read_the_segment

; We calculate crc reminder.
                        ; r13 - length of the segment.
    mov r12, buffer     ; We move pointer to buffer to r12.
.get_another_byte:
    mov al, byte [r12]  ; Load the byte from buffer.
    inc r12

    mov rcx, 8          ; Set counter of bits.
.calculate_crc:
    xor rdx, rdx
    xor rbx, rbx

    shl al, 1           ; Go to another bit.
    adc rbx, 0          ; Save shifted bit.

    shl r15, 1          ; Move to another bit of result.
    adc rdx, 0          ; Save shifted bit.

    add r15, rbx        ; Add the bit to crc reminder.

    cmp rdx, 0          ; If the removed bit was 0 we finish.
    je .skip_xoring

    xor r15, r9         ; If it wasn't zero we xor result with polynomial.

.skip_xoring:
    loop .calculate_crc

    cmp r12, r13
    jb .get_another_byte

.segment_was_empty:
    mov r12, 4
    mov r13, buffer

.read_the_offset:
    mov rax, SYS_READ
    mov rdi, r10
    mov rsi, r13
    mov rdx, r12
    syscall
    cmp rax, 0
    jle .close_the_file
    sub r12, rax
    add r13, rax
    cmp r12, 0
    ja .read_the_offset

    mov rsi, buffer
    lodsd
    movsx rsi, eax     ; Move offset to rsi register (it might be needed for lseek if it's not the end).
    add r14, rsi

; In r14 we have offset + length of segment + 6 (length of offset and bytes that give length of segment).
; If it's zero segment points to itself so we finish.
    cmp r14, 0
    jz .add_zeroes_to_crc

    mov rax, SYS_LSEEK
    mov rdi, r10
    mov rdx, SEEK_CUR
    syscall
    cmp rax, 0
    jl .close_the_file
    
    jmp .read_from_the_file

; We print crc polynomial and close the file.
.add_zeroes_to_crc:
    mov rcx, 64
.finish_xoring:
    xor rdx, rdx
    shl r15, 1          ; Move to another bit of crc reminder.
    adc rdx, 0          ; Save shifted bit.

    cmp rdx, 0          ; If the removed bit was 0 we finish.
    je .skip_xoring_2

    xor r15, r9         ; If it wasn't zero we xor reminder with polynomial.

.skip_xoring_2:
    loop .finish_xoring

    mov rcx, r8
    mov rsi, buffer_print
.move_result_to_print_buffer:
    mov r9, '0'
    shl r15, 1
    adc r9, 0
    adc byte [rsi], r9b
    inc rsi
    loop .move_result_to_print_buffer

    mov byte[rsi], END_LINE
    inc r8
    
    mov rax, SYS_WRITE
    mov rdi, STD_OUT
    mov rsi, buffer_print  ; We print result.
    mov rdx, r8            ; We print r8 (length of polynomial) characters.
    syscall
    cmp rax, 0
    jl .close_the_file

    mov rax, SYS_CLOSE
    mov rdi, r10
    syscall
    cmp rax, 0
    jl .end

    mov rax, SYS_EXIT   
    mov rdi, 0
    syscall 

; We close the file if the error occured.
.close_the_file:

    mov rax, SYS_CLOSE
    mov rdi, r10   
    syscall 

; We finish if the error occured or parameters were invalid.
.end:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall 
