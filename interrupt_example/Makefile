

CROSS = riscv64-unknown-elf
AS    = $(CROSS)-as
LD    = $(CROSS)-ld
OBJCOPY = $(CROSS)-objcopy

FLAGS = rv64gcv_zba_zbb_zbc_zbs_svinval
MABI  = lp64
TGTEMU = elf64lriscv


all: test_software_interrupt_machine_mode.elf

test_software_interrupt_machine_mode.o: test_software_interrupt_machine_mode.s
	$(AS) -march=$(FLAGS) -mabi=$(MABI) -o $@ $<

test_software_interrupt_machine_mode.elf: test_software_interrupt_machine_mode.o test.ld
	$(LD) -T test.ld -m $(TGTEMU) -o $@ test_software_interrupt_machine_mode.o

clean:
	rm -f test_software_interrupt_machine_mode.o test_software_interrupt_machine_mode.elf
