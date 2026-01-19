    #========================================================
    #set up pmpaddr0, pmpaddr1
    #then jump to the code in S mode
    #1.
    #supervisor code -> address 0x80001000 size: 4k (r=0,w=0,x=1)
    #code fetch is okay
    #2.
    #data segment -> address 0x80002000 size: 4k (r=1,w=1,x=0)
    #load/store is okay, code fetch will cause an access fault(mcause=1)
    #=========================================================
    .option norvc


    .equ INSTR_ACCESS_FAULT, 1
    .equ LD_ACCESS_FAULT,    5

    .equ BIT_MSTATUS_MPP_HI, 12
    .equ BIT_MSTATUS_MPP_LO, 11

    #=================================================
    #switch to supervisor mode
    #target pc is specified in the input "reg"
    #=================================================
    .macro switch_to_supervisor_mode reg

        csrr t0, mstatus
        bclri t0, t0, BIT_MSTATUS_MPP_HI
        bseti t0, t0, BIT_MSTATUS_MPP_LO
        csrw mstatus, t0   #mstatus.MPP = 01 (supervisor mode)
        csrw mepc, \reg    #update mepc with the target
        mret

    .endm

    #=================================================
    # program specified pmp register with base and size
    #=================================================
    #.macro init_pmp_napot num, base, size
    #.endm

    #machine mode code begins here
    .section .text
       .global _start
       _start:
        li  t0, 0xaced     #t0 --> x5 register 

        #set up exception handler
        la  t1, _handler
        ori t1, t1, 1    #mtvec.MODE = 01 (vectored)
        csrw mtvec, t1     
        
        #clear medeleg csr
        csrw medeleg, x0    

        #=========================================
        #read original values
        #disable pmpcfg0 first
        #=========================================
        csrr t4, pmpaddr0
        csrr t5, pmpcfg0
        bclri t5, t5, 4
        bclri t5, t5, 3  #t5[4:3] = 00 (OFF)
        csrw pmpcfg0, t5 #now pmpaddr0 is disabled
        

        #=========================================
        #napot set up: (base>>2)+(size>>3) - 1
        #pmpaddr0 = 0x80001000
        #pmp0cfg = NAPOT, r=0,w=0,x=1
        #pmpaddr1 = 0x80002000
        #pmp1cfg = NAPOT, r=1,w=1,x=0
        #=========================================
        bseti t4, zero, 12
        bseti t4, t4, 31     #t4 = 0x80001000
        srli  t6, t4, 2      #shift right address by 2 for pmpaddr0
        li    t5, 1
        slli  t5, t5, 12     #t5 = 4k (size)
        srli  t5, t5, 3      #size>>3
        add   t6, t6, t5     #t6 = (base>>2) + (size>>3)
        addi  t6, t6, -1     #t6 = (base>>2) + (size>>3) - 1
        csrw pmpaddr0, t6    #pmpaddr0 has base and size info
        li   t3, 0x1c
        csrw pmpcfg0, t3    #A[4:3] = 11(NAPOT), r=0,w=0,x=1 

        lui   t3, 1          #t3 = 0x1000
        add   t6, t4, t3     #t6 = t4 + t3 = 0x80002000
        srli  t6, t6, 2      #shift right address by 2 for pmpaddr1
        add   t6, t6, t5     #t6 = (base>>2) + (size>>3)
        addi  t6, t6, -1     #t6 = (base>>2) + (size>>3) - 1
        csrw pmpaddr1, t6    #pmpaddr1 has base and size info
        

        li   t5, 0x1b       #A[4:3] = 11(NAPOT), r=1,w=1,x=0
        csrr t6, pmpcfg0
        slli t5, t5, 8      #align for pmp1cfg in pmpcfg0 bits [15:8]
        or   t5, t5, t6     #preserve pmp0cfg
        csrw pmpcfg0, t5    #A[4:3] = 11(NAPOT), r=1,w=1,x=0

             
        #switch_to_supervisor_mode t4  
        #t4 still has the supervisor entry point addr (0x80001000)
        csrr t0, mstatus
        bclri t0, t0, BIT_MSTATUS_MPP_HI
        bseti t0, t0, BIT_MSTATUS_MPP_LO
        csrw mstatus, t0   #mstatus.MPP = 01 (supervisor mode)
        csrw mepc, t4      #update mepc with the target
        mret

        j test_fail         #will not get here

    test_end:
    test_pass:
        la x2, tohost
        li x1, 1            #value[0] = 1 test finished, value[63:1] = 0 = exit_code = pass
        sd x1, (x2)        
        .word 0
    test_fail:
        la x2, tohost
        li x1, 3           #value[0] = 1 test finished, value[63:1] = 1 = exit_code = fail
        sd x1, (x2)        
        .word 0

    .balign 4
    _handler:
        j _handle_exception
        .word 0
        .word 0
        .word 0
        .word 0
    _handle_exception:
        csrr t2, mcause
        li   t4, INSTR_ACCESS_FAULT
        beq  t2, t4, _finish_test
        csrr t4, mtval
        csrr t3, mepc
        addi t3, t3, 4
        mret
    _finish_test:
        j test_end

    #located at 0x80001000
    .section .scode, "ax"
        li  t5, 0x80002000
        ld  t6, (t5)  #okay r=1
        addi t6, t6, 1
        sw  t6, (t5)  #okay w=1
        jalr zero, (t5) #instruction access fault x = 0 
        


    #located at 0x80002000
    .section .data, "aw"
        .rept 4096
            .byte 1
        .endr

    .balign 8
    .global tohost
    .section  .tohost
    .align 3
    tohost:
    .dword 0

    .global fromhost
    .section  .fromhost
    .align 3
    fromhost:
    .dword 0


