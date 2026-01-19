OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS {
  . = 0x80000000;       /* typical start address for bare-metal */
  .text : { *(.text) }
  . = 0x80001000;       
  .scode : { *(.scode) }
  . = ALIGN(0x1000);
  .tohost : {*(.tohost)} 
  .fromhost : {*(.fromhost)} 
  . = ALIGN(0x1000);
  .data : { *(.data) }
  .bss  : { *(.bss)  }
  _end = .;
}
