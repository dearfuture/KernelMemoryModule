;
;
; Copyright (c) 2015-2017 by blindtiger ( blindtiger@foxmail.com )
;
; The contents of this file are subject to the Mozilla Public License Version
; 2.0 (the "License"); you may not use this file except in compliance with
; the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
;
; Software distributed under the License is distributed on an "AS IS" basis,
; WITHOUT WARRANTY OF ANY KIND, either express or implied. SEe the License
; for the specific language governing rights and limitations under the
; License.
;
; The Initial Developer of the Original e is blindtiger.
;
;

.686
.XMM

    .XLIST
INCLUDE KS386.INC
INCLUDE CALLCONV.INC
    .LIST

OPTION CASEMAP:NONE

_DATA$00 SEGMENT PAGE 'DATA'

_DATA$00 ENDS

_TEXT$00 SEGMENT PAGE 'CODE'

cPublicProc _ExecuteHandlerForException, 5

    mov edx, offset FLAT : _ExceptionHandler ; Set who to register
    jmp _ExecuteHandler                      ; jump to common code

    int 3

stdENDP _ExecuteHandlerForException

align 20h

cPublicProc _ExecuteHandler, 5

    push ebx
	push esi
	push edi
	xor eax, eax
	xor ebx, ebx
	xor esi, esi
	xor edi, edi
	push [esp + 32]                         ; ExceptionRoutine
	push [esp + 32]                         ; DispatcherContext
	push [esp + 32]                         ; ContextRecord
	push [esp + 32]                         ; EstablisherFrame
	push [esp + 32]                         ; ExceptionRecord

	Call _ExecuteHandler2

	pop edi
	pop esi
	pop ebx

    stdRET _ExecuteHandler

    int 3

stdENDP _ExecuteHandler

align 20h

cPublicProc _ExecuteHandler2, 5

ExceptionRecord equ [ebp + 8]
EstablisherFrame equ [ebp + 12]
ContextRecord equ [ebp + 16]
DispatcherContext equ [ebp + 20]
ExceptionRoutine equ [ebp + 24]

    push ebp
    mov ebp,esp

    push EstablisherFrame                   ; Save context of exception handler
                                            ; that we're about to call.

.errnz ErrHandler - 4
    push edx                                ; Set Handler address

.errnz ErrNext - 0
    push fs : PcExceptionList               ; Set next pointer
    mov fs : PcExceptionList,esp            ; Link us on

; Call the specified exception handler.

    push DispatcherContext
    push ContextRecord
    push EstablisherFrame
    push ExceptionRecord
    
    mov ecx, ExceptionRoutine
    call ecx
    mov esp, fs : PcExceptionList

; Don't clean stack here, code in front of ret will blow it off anyway

; Disposition is in eax, so all we do is deregister handler and return

.errnz  ErrNext - 0
    pop fs : PcExceptionList
    
    mov esp, ebp
    pop ebp
    
    stdRET _ExecuteHandler2

    int 3

stdENDP _ExecuteHandler2

align 20h

cPublicProc _ExceptionHandler, 4

Unwind equ EXCEPTION_UNWINDING OR EXCEPTION_EXIT_UNWIND

    mov ecx, dword ptr [esp + 4]            ; (ecx) -> ExceptionRecord
    test dword ptr [ecx.ErExceptionFlags], Unwind
    mov eax,ExceptionContinueSearch         ; Assume unwind
    jnz eh10                                ; unwind, go return

;
; Unwind is not in progress - return nested exception disposition.
;

    mov ecx, [esp + 8]                      ; (ecx) -> EstablisherFrame
    mov edx, [esp + 16]                     ; (edx) -> DispatcherContext
    mov eax, [ecx + 8]                      ; (eax) -> EstablisherFrame for the
                                            ;          handler active when we
                                            ;          nested.
    mov [edx], eax                          ; Set DispatcherContext field.
    mov eax, ExceptionNestedException

eh10:
    stdRET _ExceptionHandler

    int 3

stdENDP _ExceptionHandler

align 20h

_TEXT$00 ENDS

END
