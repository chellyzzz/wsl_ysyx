ENTRY(_start)

MEMORY 
{
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  sdram : ORIGIN = 0xa0000000, LENGTH = 32M
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS 
{
  . = ORIGIN(flash);

  .text.fsbootloader :
  {
    _fsbl = .;
    *(entry)
    *(.text.fsbl)
    _efsbl = .;
    . = ALIGN(4);
  } > flash AT >flash 

  .text.ssbootloader :
  {
    _ssbl = .;
    *(.text.ssbl)
    _essbl = .;
    . = ALIGN(4);
  } > sram AT >flash 
  ssbl_flash_start = LOADADDR(.text.ssbootloader);

  .text : 
  {
    _text = .;
    *(.text*)
    _etext = .;
    . = ALIGN(4);
  } > sdram AT >flash 
  text_flash_start = LOADADDR(.text);

  .rodata : 
  {
    _rodata = .;
    *(.rodata*)
    *(.srodata)
    *(.srodata.*)
    . = ALIGN(4);
    _erodata = .;
  } > sdram AT >flash


  .data : 
  {
    _data = .;
    *(.data)
    *(.data.*)
    *(.sdata)
    *(.sdata.*)
    _edata = .;
    . = ALIGN(4);
  } > sdram AT >flash 
  data_flash_start = LOADADDR(.data);

  .bss : 
  {
    _bstart = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bend = .;
    . = ALIGN(4);
  } > sdram AT >flash

  end = .;
  _end = .;
  _heap_start = ALIGN(0x100);
  _heap_end = _heap_start + 0x40000;
  _stack_top = ALIGN(0x100);
  . = _stack_top + _sram_size - 0x100;
  _stack_pointer = .;
} 