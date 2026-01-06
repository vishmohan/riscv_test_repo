    .option norvc

    #machine mode code begins here
    .section .text
       .global _start
       _start:
        li  t0, 0xaced     #t0 --> x5 register 

        #set up exception handler
        la  t1, _handler
        csrw mtvec, t1     #t1 --> x6
        
        #clear medeleg csr
        csrw medeleg, x0    

        ecall               #stay in machine mode
                            #go to _handler (address in mtvec)
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
        j test_end


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


