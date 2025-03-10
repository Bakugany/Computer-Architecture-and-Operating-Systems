global mdiv;

section .text

mdiv:
; At the beginning parameters are loaded to three registers:
; Pointer to the array of big number is in rdi register.
; Length of big number is in rsi register.
; Divisor is in rdx register.

; Rdx register will be needed for performing the division so the divisor is being moved to r10 register.
        mov r10, rdx

; Sign byte of dividend is being move to r8 register. 
        mov r8, [rdi + 8 * rsi - 8]     ; First the most important 64 bytes are move to r8.
        shr r8, 63                      ; And now shift gets rid of all but sign byte.

; Similarly sign of divisor is being moved to r9 register.
        mov r9, r10
        shr r9, 63

; If divisor in negative it's being changed to it's absolute value.
        test r9, r9                     ; It checks whether byte sign of divisor is 1 or 0.
        jz .divisor_is_positive         ; If it's zero jump is performed.
        neg r10 ;                       ; Otherwise divisor is being negated.
.divisor_is_positive:

; Similarly if dividend is negative it's being changed to it's positive value.
; It's being done in two steps. First all bytes are changed to opposite and then one is added to divided.
        test r8, r8                     ; It checks whether byte sign of dividend is 1 or 0.
        jz .dividend_is_positive        ; If it's zero jump is performed.
        mov rcx, rsi                    ; Otherwise rcx register is being set as iterator.      
        lea rdx, [rdi]                  ; Adress of the beginning of dividend is loaded to rdx register.
.change_to_opposite: 
        not qword [rdx]                 ; Bytes of that part of dividend are being changed to the opposite.
        add rdx, 8                      ; Pointer is being moved to another part of dividend.
        loop .change_to_opposite        ; Loop is performed as long as whole dividend is not changed to the opposite.
; Now it's time to add missing plus one.
        mov rcx, rsi                    ; Rcx register is being set as iterator.
        lea rdx, [rdi]                  ; Adress of the beginning of dividend is loaded to rdx register.
.add_one:
        add rdx, 8                      ; Pointer is being moved to another part of dividend.
        add qword [rdx - 8], 1          ; One is being added to that part (I choose add instruction because inc doesn't change carry flag)
        jc .add_one                     ; If carry flag is set one needs to be carried to another part of dividend.
.dividend_is_positive:

; All numbers have been changed to their absolute value. Now it's time to divide.
        xor rdx, rdx                    ; Rdx register is being set to 0.
        mov rcx, rsi                    ; Rcx register is being set as iterator.
; Now in loop column division is being done.
.division:  
        mov rax, [rdi + 8 * rcx - 8]    ; Parts of dividend starting with the most important bytes are being moved to rax register.
        div r10                         ; Number in rdx:rax is being divided by value is r10 resgister (dividend)
        mov [rdi + 8 * rcx - 8], rax    ; Result is going back to starting array.
        loop .division                  ; Loop is being performed so long as whole dividend is not divided.
        mov rax, rdx                    ; After all divisions reminder is being move from rdx register to rax register.

; There was one situation when overflow was possible. It happend if and only if divisor is negative and byt sign of result of performed division is one.
        test r9, r9                     ; It checks whether byte sign of divisor is 1 or 0.
        jz .not_overflow                ; If it's 0 overflow is impossible so jump is performed.
; Otherwise sign of the result needs to be checked.
        mov rcx, [rdi + 8 * rsi - 8]    ; The most important 64 bytes of result are being moved to rcx register.
        shr rcx, 63                     ; Shift get's rid of all but sign byte.
        test rcx, rcx                   ; It checks whether byt sing of result is 1 or 0.
        jnz .overflow                   ; If it's one then overflow has occurred. 
.not_overflow:

; If it's not overflow situation signs of result and remindered needs to be adjusted.
; Sign of reminder is negative if and only if sign of dividend was negative.
        test r8, r8                     ; It checks whether byt sign of dividend is 1 or 0.
        jz .sign_of_reminder_is_correct ; If it's 0 sign of reminder is correct so jump is performed.
        neg rax                         ; Otherwise reminder is being negated.
.sign_of_reminder_is_correct:

; Sign of result is negative if and only if signs of dividend and divisor were different.
        cmp r8,r9                       ; Signs of divided and divisor are being compared.
        je .sign_of_result_is_correct   ; If they're equal sign is correct so jump is performed.
; Otherwise result is being negated.
; It's the same piece of code as in lines 32-44 (when sign of dividend had been changed), so I won't comment it again.
        mov rcx, rsi 
        lea rdx, [rdi]
.change: 
        not qword [rdx]
        add rdx, 8
        loop .change

        lea rdx, [rdi]
        mov rcx, rsi
.add:
        add rdx, 8
        add qword [rdx - 8], 1
        jc .add
.sign_of_result_is_correct:
        ret 

; If there was overflow divison by zero is being performed.
.overflow:
        xor r8, r8                      ; It zeroes r8 register.
        div r8                          ; It divides by r8 register, which was set to 0. 
        ret