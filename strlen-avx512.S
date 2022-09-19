#define SYS_write	0x1

#define STDOUT_FILENO	0x1


#define I_WRITE_BASE(fileno, data, sz)	\
	leaq	I_reg_buf(%rip), %rsi;	\
	movq	data, (%rsi);	\
	movl	$fileno, %edi;	\
	movl	$sz, %edx;	\
	movl	$SYS_write, %eax;	\
	syscall;

#define I_WRITE(fileno, data)	\
	I_WRITE_BASE (fileno, data, 8);	\

#define WRITE_REG_STDOUT(reg)	I_WRITE(STDOUT_FILENO, %reg)


#define RDTSC_TO_REG(other)	\
	rdtsc;	\
	salq	$32, %rdx;	\
	leaq	(%rax, %rdx), %other


	.section .data.reg_buf, "aM", @progbits, 8
	.p2align 3
I_reg_buf:	.space 8

// gcc -s -static -nostartfiles -nodefaultlibs -nostdlib -Wl,--build-id=none strlen-avx512.S -o strlen-avx512


#define LEN	(4096 * 12)

#define VEC_SIZE	64
#define N	4
    //#define INSN	vpminub
//    #define INSN vpandq
#if VEC_SIZE == 64
# define PRIM_VEC(n)	zmm ## n
# define VEC(n)	PRIM_VEC(n)
# define GPR	rcx
# define kmov	kmovq
#else
# define PRIM_VEC(n)	ymm ## n
# define VEC(n)	PRIM_VEC(n)
# define GPR	ecx
# define kmov	kmovd
#endif

	.global	_start
	.p2align 6
	.text
_start:
	leaq	(buf_start)(%rip), %rdi
	movl	$-1, %eax
	movl	$LEN, %ecx

	rep	stosb
	leaq	(buf_start)(%rip), %rdi
	movq	%rdi, %rsi

	movb	$0, (LEN -1)(%rdi)

	vpxorq	%xmm16, %xmm16, %xmm16

	RDTSC_TO_REG (r8)


	movl	$1000000, %eax


	.p2align 6
loop:
	vmovdqa64 (%rdi), %VEC(17)
	INSN	VEC_SIZE(%rdi), %VEC(17), %VEC(22)
#if N == 4
	vmovdqa64 (VEC_SIZE * 2)(%rdi), %VEC(18)
	INSN	(VEC_SIZE * 3)(%rdi), %VEC(18), %VEC(19)
	INSN	%VEC(19), %VEC(22), %VEC(22)
#endif
	vptestnmb %VEC(22), %VEC(22), %k0
	kmov	%k0, %GPR
	subq	$-(VEC_SIZE * N), %rdi
	test	%GPR, %GPR
	jz	loop
	movq	%rsi, %rdi
	decl	%eax
	jnz	loop

	RDTSC_TO_REG (r9)

	subq	%r8, %r9
	WRITE_REG_STDOUT (r9)

	movl	$60, %eax
	xorl	%edi, %edi
	syscall

#if 1
	.section .data
	.balign	4096
buf_start:	.space LEN
buf_end:
#endif
