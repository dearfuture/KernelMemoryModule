# KernelMemoryModule

AMD64 kernel module need bypass PatchGuard.

I386 user module need replace __ValidateEH3RN

__ValidateEH3RN :

    mov edi, edi

    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]
    test byte ptr [eax + 8], 3
    mov eax, 0
    setz al

    mov esp, ebp
    pop ebp

    ret
    
    int 3

PUBLIC __ValidateEH3RN
