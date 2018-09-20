;;-----------------------------------
;; int slen(String message)
;; String length calculation function
slen:
        push ebx
        mov ebx, eax

nextchar:
        cmp byte [eax], 0
        jz finished
        inc eax
        jmp nextchar

finished:
        sub eax, ebx
        pop ebx
        ret

;;-----------------------------------
;; void sprint(String message)
;; String printing function
sprint:
        push edx
        push ecx
        push ebx
        push eax
        call slen

        mov edx, eax
        pop eax

        mov ecx, eax
        mov ebx, 1
        mov eax, 4
        int 80h

        pop ebx
        pop ecx
        pop edx

        ret

;;-----------------------------------
;; void sprintLF(String message)
;; String printing with line feed function
sprintLF:
        call sprint
        push eax                ; Push EAX onto the stack
        mov eax, 0Ah            ; Move linefeed into EAX
        push eax                ; Save linefeed onto the stack
        mov eax, esp            ; Move the address of the stack into EAX
        call sprint             ; Call our sprint function
        pop eax                 ; Remove linefeed character from stack
        pop eax                 ; Restore original
        ret

;;-----------------------------------
;; void exit()
;; Exit program and restore resources
quit:
        mov ebx, 0
        mov eax, 1
        int 80h
        ret
