ENTRY(_start)
KERNEL_VIRT_BASE = 0xFFFFFFFF80000000;
KERNEL_PHYS_BASE = 0x00100000;

/*
    ELF segment table
    Tells the linker how to group the sections into ELF segments
    so that Limine can read and load them correctly into memory
*/
PHDRS
{
    requests PT_LOAD FLAGS(4);
    text     PT_LOAD FLAGS(5);
    rodata   PT_LOAD FLAGS(4);
    data     PT_LOAD FLAGS(6);
}

SECTIONS
{
    . = KERNEL_VIRT_BASE + KERNEL_PHYS_BASE;
    kernel_virt_start = .;
    kernel_phys_start = . - KERNEL_VIRT_BASE;

    .limine_requests_start ALIGN(4096) : AT(ADDR(.limine_requests_start) - KERNEL_VIRT_BASE)
    {
        KEEP(*(.limine_requests_start))
    } :requests

    .limine_requests ALIGN(8) :
    {
        KEEP(*(.limine_requests))
    } :requests

    .limine_requests_end ALIGN(4096) :
    {
        KEEP(*(.limine_requests_end))
    } :requests

    _text_start = .;
    .text ALIGN(4096) : AT(ADDR(.text) - KERNEL_VIRT_BASE)
    {
        *(.text._start)     /* entry point to first */
        *(.text)
        *(.text.*)
    } :text

    . = ALIGN(4096);
    _text_end = .;

    _rodata_start = .;
    .rodata ALIGN(4096) : AT(ADDR(.rodata) - KERNEL_VIRT_BASE)
    {
        *(.rodata)
        *(.rodata.*)
    } :rodata

    . = ALIGN(4096);
    _rodata_end = .;

    _data_start = .;
    .data ALIGN(4096) : AT(ADDR(.data) - KERNEL_VIRT_BASE)
    {
        *(.data)
        *(.data.*)
    } :data

    .bss ALIGN(4096) :
    {
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        . = ALIGN(4096);
        _bss_end = .;
    } :data

    /* Stack in the BSS or dedicated */
    .stack ALIGN(4096) :
    {
        _stack_bottom = .;
        . += 0x10000;   /* 64 KiB */
        _stack_top = .;
    } :data

    kernel_virt_end = .;
    kernel_phys_end = . - KERNEL_VIRT_BASE;
}
