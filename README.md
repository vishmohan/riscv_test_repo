Before using this repository please follow the steps below:

Step 1: Install riscv tool chain:
---------------------------------
To install riscv tool chain see instructions in:
https://github.com/riscv-collab/riscv-gnu-toolchain

Use the install option with multi-lib:
./configure --prefix=/opt/riscv --enable-multilib

Step 2: Install spike
---------------------
Use instructions in:
https://github.com/riscv-software-src/riscv-isa-sim
From the instructions:
 ../configure --prefix=$RISCV --> RISCV=/opt/riscv from step1 (riscv tool chain install)  


Now you are ready to use the tests in this repository:
------------------------------------------------------
After having installed the riscv tool chain and the spike isa:

# riscv_test_repo
Contains bare metal riscv testsrun with spike iss

1. use the Makefile which will invoke the assembler and linker to generate the elf executable

2. To run spike on the binary:
    spike -l --log-commits  --pc=0x80000000 --isa=rv64gcv_zba_zbb_zbs_svinval <testname>.elf 2> spike.log










