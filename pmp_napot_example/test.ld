OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS {
  . = 0x80000000;       /* typical start address for bare-metal */
  .text : { *(.text) }
  . = 0x80001000;       
  .scode : { *(.scode) }
  . = 0x80002000;       
  .data : { *(.data) }
  .tohost : {*(.tohost)} 
  .fromhost : {*(.fromhost)} 
  . = ALIGN(0x1000);
  .bss  : { *(.bss)  }
  _end = .;
}
