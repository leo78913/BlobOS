[bits 32]
%define HEADER_LENGTH header_end - header_start
%define MAGIC 0xe85250d6
%define CHECKSUM 0x100000000 -(MAGIC + 0 + (HEADER_LENGTH))
section .multiboot2
align 4
header_start:
	dd MAGIC ; The Multiboot 2 Magic number
	dd 0 ; 32-bit Protected Mode (Architecture)
	dd HEADER_LENGTH
	dd CHECKSUM ; Proving that we're who we're.

	dw 0
	dw 0
	dd 8

header_end:

global _start:function (_start.end - _start)
global _ClearTables
global _SetupPaging
global _EnablePAE
global _LongMode
global _EnablePaging

%include "Arch/x86_64/gdt.asm"

; note, that if you are building on Windows, C functions may have "_" prefix in assembly: _kernel_main
extern ArchInit
extern Realm64

section .text
bits 32
_start:
	mov esp, stack_top ; Set the esp register to the top of the stack, as it grows downwards.

	call ArchInit
	lgdt [gdt_descriptor]
	jmp 0x08:Realm64

	; EBX holds the pointer to the Multiboot info structure.
	;push ebx
	;call Kmain
	;add esp, 8

.hang: 
	hlt
	jmp .hang
.end:

_ClearTables:
    mov edi, 0x1000    ; Set the destination index to 0x1000.
    mov cr3, edi       ; Set control register 3 to the destination index.
    xor eax, eax       ; Nullify the A-register.
    mov ecx, 4096      ; Set the C-register to 4096.
    rep stosd          ; Clear the memory.
    mov edi, cr3       ; Set the destination index to control register 3.
	ret

_SetupPaging:
    mov DWORD [edi], 0x2003      ; Set the uint32_t at the destination index to 0x2003.
    add edi, 0x1000              ; Add 0x1000 to the destination index.
    mov DWORD [edi], 0x3003      ; Set the uint32_t at the destination index to 0x3003.
    add edi, 0x1000              ; Add 0x1000 to the destination index.
    mov DWORD [edi], 0x4003      ; Set the uint32_t at the destination index to 0x4003.
    add edi, 0x1000              ; Add 0x1000 to the destination index.
    mov ebx, 0x00000003          ; Set the B-register to 0x00000003.
    mov ecx, 512                 ; Set the C-register to 512.
.SetEntry:
    mov DWORD [edi], ebx         ; Set the uint32_t at the destination index to the B-register.
    add ebx, 0x1000              ; Add 0x1000 to the B-register.
    add edi, 8                   ; Add eight to the destination index.
    loop .SetEntry               ; Set the next entry.

_EnablePAE:
    mov eax, cr4                 ; Set the A-register to control register 4.
    or eax, 1 << 5               ; Set the PAE-bit, which is the 6th bit (bit 5).
    mov cr4, eax                 ; Set control register 4 to the A-register.
	ret

_LongMode:
    mov ecx, 0xC0000080          ; Set the C-register to 0xC0000080, which is the EFER MSR.
    rdmsr                        ; Read from the model-specific register.
    or eax, 1 << 8               ; Set the LM-bit which is the 9th bit (bit 8).
    wrmsr                        ; Write to the model-specific register.
	ret

_EnablePaging:
    mov eax, cr0                 ; Set the A-register to control register 0.
    or eax, 1 << 31              ; Set the PG-bit, which is the 32nd bit (bit 31).
    mov cr0, eax                 ; Set control register 0 to the A-register.
	ret

section .bss
align 4096
stack_bottom:
resb 4096 * 4 ; 16 KiB
stack_top:
