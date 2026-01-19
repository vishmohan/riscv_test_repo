CROSS = riscv64-unknown-elf
AS    = $(CROSS)-as
LD    = $(CROSS)-ld
OBJCOPY = $(CROSS)-objcopy

FLAGS = rv64gcv_zba_zbb_zbc_zbs_svinval
MABI  = lp64
TGTEMU = elf64lriscv


all: test_pmp_napot.elf

test_pmp_napot.o: test_pmp_napot.s
	$(AS) -march=$(FLAGS) -mabi=$(MABI) -o $@ $<

test_pmp_napot.elf: test_pmp_napot.o test.ld
	$(LD) -T test.ld -m $(TGTEMU) -o $@ test_pmp_napot.o

clean:
	rm -f test_pmp_napot.o test_pmp_napot.elf
