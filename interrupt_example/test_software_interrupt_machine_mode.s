    #=======================
    #Test generates a machine mode software interrupt
    #by writing to the memory mapped CLINT.
    #The interrupt handler clears the pending interrupt
    #and jumps to test_end 
    #=======================
    .option norvc

    #machine mode code begins here
    .section .text
       .global _start
       _start:
        li  t0, 0xaced     #t0 --> x5 register 

        #step 1:
        #set up exception handler
        la  t1, _handler
        ori t1, t1, 1      
        csrw mtvec, t1      #mtvec.BASE = _handler    
                            #mtvec.MODE =  Vectored        

        #clear medeleg csr
        csrw medeleg, x0    


        
        #step 2:
        #enable interrupts globally in machine mode by setting mstatus.MIE
        .equ BIT_MSTATUS_MIE, 3
        csrsi mstatus, 1<<BIT_MSTATUS_MIE #mstatus[3] = 1 --> enables interrupts in machine mode

        #set the mmode software interrupt pending bit in mip
        .equ BIT_MIP_MSIP, 3
        .equ BIT_MIE_MSIE, 3

        #step 3:
        csrsi mie, 1<<BIT_MIE_MSIE #mie[3] = 1 enable recognition of mmode software interrupt

        #step 4:
        #MSIP is read only - Generate software interrupt by writing to CLINT
        #In spike CLINT lives at memory 0x0200_0000 see platform.h in spike source
        .equ CLINT_BASE, 0x02000000
        li t0, CLINT_BASE
        li t1, 1
        sw t1, (t0)                #this sets the software interrupt pending for hart0
        j     .                    #create infinite loop interrupt recognized at this pc


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
        j _handle_exception  #bytes 0-3
        .word 0              #bytes 4-7
        .word 0              #bytes 8-11
        j _handle_software_interrupt_M_mode #bytes 12-15

    _handle_exception:
        csrr t2, mcause
        csrr t3, mepc
        csrr t4, mtval
        addi t3, t3, 4
        csrw mepc, t3   #mepc = mepc + 4 (next pc to return to)
        mret            #return to pc following the exception pc

    _handle_software_interrupt_M_mode:
        csrr t2, mcause
        csrr t3, mepc
                        #t0 still contains CLINT_BASE
        sw zero, (t0)   #this clears the pending software interrupt for core0
        addi t3, t3, 4
        csrw mepc, t3   #mepc = mepc + 4 (next pc to return to)
        mret            #return to pc following the interrupt pc


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


