%include 'functions.asm'

%define maxInputSize 0ffffh
%define memorySize 30000

SECTION .data
        noArgsMsg db 'Expected one argument', 0h
        couldNotOpenFileMsg db 'Could not open file', 0h
        inputTooLargeMsg db 'Input program is too large', 0h
        unmatchedLoopEndMsg db 'Unexpected ]', 0h
        unmatchedLoopStartMsg db 'Unexpected [', 0h

SECTION .bss
program: resb maxInputSize
memory: resb memorySize

SECTION .text
global _start

_start:
        nop
        pop ecx                 ; Get the number of arguments
        cmp ecx, 2h             ; Check if there are two argument
        jne noArgs              ; Exit the program with an error message

;; Open the file
        pop ebx                 ; First argument should be the binary itself
        pop ebx                 ; Second argument is the brainfuck program path
        mov ecx, 0              ; No flags
        mov edx, 0              ; Use O_RDONLY mode
        mov eax, 5              ; Invoke SYS_OPEN
        int 80h

;; Check if file was opened
        test eax, eax           ; Check result
        js couldNotOpenFile     ; The sign flag is negative

;; Initialize read loop
        mov ebx, eax            ; Store the file descriptor in ebx to read from it
        mov esi, 0              ; Set counter of bytes read t 0
        mov ecx, program        ; Read into program
        mov edx, 1              ; Read 1 byte

readProgramByte:
        mov eax, 3              ; Invoke SYS_READ
        int 80h

;; Only read brainfuck instructions and skip everything else
        cmp byte [ecx], '+'
        je keepByte
        cmp byte [ecx], '-'
        je keepByte
        cmp byte [ecx], '>'
        je keepByte
        cmp byte [ecx], '<'
        je keepByte
        cmp byte [ecx], ','
        je keepByte
        cmp byte [ecx], '.'
        je keepByte
        cmp byte [ecx], '['
        je keepByte
        cmp byte [ecx], ']'
        je keepByte

        mov byte [ecx], 0       ; Clear the last read byte
        jmp skipByte            ; Don't increment pointer & counter

keepByte:
        inc ecx                 ; Increment program buffer pointer
        inc esi                 ; Increment counter
skipByte:

        cmp esi, maxInputSize   ; Check if we have read 4096 bytes
        je inputTooLarge        ; The program is too large

        cmp eax, 0              ; Check for EOF
        jne readProgramByte     ; Read next byte if not EOF

        mov eax, 6              ; Invoke SYS_CLOSE
        int 80h

;; Initialize execution loop
        mov edx, memory         ; Set memory pointer to memory start
        mov esi, program        ; Set brainfuck instruction pointer to the program start
        mov edi, 0              ; Set loop depth to 0

run:
        cmp byte [esi], 0       ; Check for 0 byte
        je exit                 ; If instruction is 0 the program is over

;; Handle current instruction
        cmp byte [esi], '+'
        je plus
        cmp byte [esi], '-'
        je minus
        cmp byte [esi], '>'
        je right
        cmp byte [esi], '<'
        je left
        cmp byte [esi], ','
        je read
        cmp byte [esi], '.'
        je write
        cmp byte [esi], '['
        je startLoop
        cmp byte [esi], ']'
        je endLoop

next:
        inc esi                 ; Increment instruction pointer
        jmp run                 ; Continue

plus:
        inc byte [edx]          ; Increment memory cell
        jmp next                ; Next instruction

minus:
        dec byte [edx]          ; Decrement memory cell
        jmp next                ; Next instruction

right:
        inc edx                 ; Increment memory pointer
        jmp next                ; Next instruction

left:
        dec edx                 ; Decrement memory pointer
        jmp next                ; Next instruction

read:
        mov ecx, edx            ; Read into current memory cell
        push edx                ; Preserve memory pointer
        mov edx, 1              ; Read 1 byte
        mov ebx, 0              ; Read from STDIN
        mov eax, 3              ; Invoke SYS_READ
        int 80h

        pop edx                 ; Restore memory pointer
        jmp next                ; Next instruction

write:
        push ecx                ; Preserve ecx
        push ebx                ; Preserve ebx
        push eax                ; Preserve eax
        mov ecx, edx            ; Write edx (memory)
        push edx                ; Preserve edx

        mov edx, 1              ; Write 1 byte
        mov ebx, 1              ; Write to STDOUT
        mov eax, 4              ; Invoke SYS_WRITE
        int 80h

        pop edx                 ; Restore edx
        pop eax                 ; Restore eax
        pop ebx                 ; Restore ebx
        pop ecx                 ; Restore ecx

        jmp next                ; Continue

startLoop:
        cmp byte [edx], 0       ; Check if memory cell is zero
        mov eax, 1              ; Initialize counter for '['
        mov ebx, 0              ; Initialize counter for ']'
        jz gotoLoopEnd          ; Got to the end of the loop

        inc edi                 ; Increment loop depth
        push esi                ; Push brainfuck instruction pointer onto the stack
        jmp next                ; Execute first instruction in loop body

gotoLoopEnd:
        inc esi                 ; Increment esi to check next instructions
        cmp byte [esi], 0       ; Check for EOF
        jz unmatchedLoopStart   ; There was an unmatched '['

        cmp byte [esi], '['     ; Check if current instruction is '['
        je foundStart           ; Handle '['
        cmp byte [esi], ']'     ; Check if current instruction is ']
        je foundEnd             ; Handke ']'

        jmp gotoLoopEnd         ; Check next instruction

foundStart:
        inc eax                 ; Increment '[' count
        jmp gotoLoopEnd         ; Check next instruction

foundEnd:
        inc ebx                 ; Increment ']' count
        cmp eax, ebx            ; Compare '[' and ']' count
        je next                 ; If they are equal continue after the loop
        jl unmatchedLoopEnd     ; If there are less '[' there is an unmatched '['
        jmp gotoLoopEnd         ; Otherwise check next instruction

endLoop:
        cmp edi, 0              ; Check if loop depth is zero
        jz unmatchedLoopEnd     ; There was an unmatched ']'

        cmp byte [edx], 0        ; Check if memory cell is zero
        jnz rerunLoop           ; Execute loop again

        pop eax                 ; Drop loop beginning
        dec edi                 ; Decrement loop depth
        jmp next

rerunLoop:
        pop esi                 ; Restore loop beginning instruction
        push esi                ; Push it onto the stack
        jmp next                ; Execute first instruction in loop body

exit:
        call quit

noArgs:
        mov eax, noArgsMsg      ; Store error message in eax
        call sprintLF           ; Print it

        call quit

couldNotOpenFile:
        mov eax, couldNotOpenFileMsg ; Store error message in eax
        call sprintLF                ; Print it

        call quit

inputTooLarge:
        mov eax, inputTooLargeMsg ; Store error message in eax
        call sprintLF             ; Print it

        call quit

unmatchedLoopEnd:
        mov eax, unmatchedLoopEndMsg ; Store error message in eax
        call sprintLF                ; Print it

        call quit

unmatchedLoopStart:
        mov eax, unmatchedLoopStartMsg ; Store error message in eax
        call sprintLF                  ; Print it

        call quit
