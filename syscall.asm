.arm
.ifndef SYSCALL_ASM
.equ	SYSCALL_ASM, 	0x0

.equ	STDIN_FILENO,	0x0000
.equ	STDOUT_FILENO,	0x0001

.equ	SYS_EXIT,	0x0001
.equ	SYS_READ,	0x0003
.equ	SYS_WRITE,	0x0004

.equ	SYS_IOCTL,	0x0036
.equ	SYS_POLL,	0x00A8




.ifndef SYSCALL
.macro  SYSCALL
	svc #0
.endm
.endif /* SYSCALL */

.endif /* SYSCALL_ASM */
