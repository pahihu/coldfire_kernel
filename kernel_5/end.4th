( disk tables)
HEX
.S .( finish_vocabularies) CR
 send
finish_vocabularies
.( object_fix_wordlist)
.S send
object_fix_wordlist

\ User dictionary consumed when creating kernel
.( setup dictionaty)
.S send
'dictionary @ DUP _('dictionary_remember) t! _(hremember) dt!  



\ fast memory area consumed while creating kernel
'tfast @ _(fast_remember) dt!

\ static memory area consumed while createing kernel
#BVP5552 #BVP5551 + [IF]
	'tstatic @ _(static_remember) dt!
[THEN]

'tport @ _(port_remember) dt!

\ move to long word boundry
ram_here 2 + $FFFFFFFC AND ram_here - ram_allot

\ User area consumed by kernel
ram_here 

Smax Rmax + + _(ubase)   t!
'U @ _(uremember) dt!
Umax _(utop) t!

ram_here  Smax .S + _(s0) t!
Smax Rmax Umax + + .S ram_allot ram_here  _(rremember) dt!

HERE .( Here: ) .h SPACE ram_here .( There: ) .h send

DECIMAL  
HOST HERE forth _prom_kernel_start -              \ n (--
DUP KERNEL_CHECKSUM                               \ n checksum (--
HOST DUP _prom_kernel_checksum t! _%kernel_checksum dt! \ n(--
_prom_kernel_count t!

dictionary_here _#dictionary_start - 8 - DUP _dictionary_checksum
_application_checksum dt! _application_count dt! 
