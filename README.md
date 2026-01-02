# riscv_test_repo
Contains directed riscv run with spike iss


After having installed the riscv tool chain and the spike isa:


1. use the Makefile which will invoke the assembler and linker to generate the elf executable

2. To run spike on the binary:
    spike -l --log-commits  --pc=0x80000000 --isa=rv64gcv_zba_zbb_zbs_svinval <testname>.elf 2> spike.log










