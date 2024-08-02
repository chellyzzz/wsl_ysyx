void ssbl() __attribute__((section(".text.ssbl"), noinline));
void fsbl() __attribute__((section(".text.fsbl")));
void _trm_init();
void fsbl(){
    extern char _ssbl, ssbl_flash_start, _essbl;
    volatile char *src = &ssbl_flash_start;
    volatile char *dst = &_ssbl;
    volatile char *end = &_essbl;
    /* ROM has data at end of text; copy it.  */
    while (dst < end)
      *dst++ = *src++;
    ssbl();
}
void ssbl(){
    extern char _text, text_flash_start, _erodata;
    volatile char *src = &text_flash_start;
    volatile char *dst = &_text;
    volatile char *end = &_erodata;
    /* ROM has data at end of text; copy it.  */
    while (dst < end)
      *dst++ = *src++;

    extern char _data, data_flash_start, _edata;
    src = &data_flash_start;
    dst = &_data;
    end = &_edata;
    /* ROM has data at end of text; copy it.  */
    while (dst < end)
      *dst++ = *src++;

    /* Zero bss.  */
    //TODO: zero bss

    _trm_init();
    
}