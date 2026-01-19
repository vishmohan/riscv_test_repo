    #====================================================================
    #set up pmpaddr0
    #setup pmpcfg0.pmp0cfg(for pmpaddr0 to be NA4 mode)
    #then jump to the code in S mode

    #pmpaddr0 = 0x80001000
    #pmpcfg0  = NA4 mode, read,write,execute permissions
    #the first 4 bytes have rwx permissions from base 0x80001000
    #After the first instruction is executed, PC switches to 0x80001004
    #This PC does not have any pmp permissions and triggers an instruction access fault
    #mcause = 1
    #=====================================================================
    .option norvc


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
        #set up region at address 0x80001000
        #to have access for the first 4 bytes
        #Test will execute the first instruction
        #Then there will be an access fault
        #=========================================
        bseti t4, zero, 12
        bseti t4, t4, 31    #t4 = 0x80001000
        srli t6, t4, 2      #shift right address by 2 for pmpaddr0
        csrw pmpaddr0, t6
        li   t5, 0x17
        csrw pmpcfg0, t5    #A[4:3] = 10(NA4) 

             
        switch_to_supervisor_mode t4  #t4 still has the supervisor entry point addr (0x80001000)

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
        csrr t2, mcause
        csrr t3, mepc
        csrr t4, mtval
        j test_end


    .section .scode, "aw"
        addi t4, zero, 1  #t4 = x29 = 1
        nop               #I side accessfault here (no pmp permissions)
        nop


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


