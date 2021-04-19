\ <a HREF="./license.html">license</a>

HEX

 forth : LOOP  ( -- \ addr 3 --)
		HOST COMPILE _do_loop
		forth BEGIN
			DUP HOST _#comp_code_leave forth =
		WHILE
			DROP
			\ still havn't added in loop offset
			HOST HERE forth 2+ OVER -  SWAP HOST TW! forth 
		REPEAT
    	DUP ABS  HOST _#comp_code_do  ?PAIR forth OVER HOST !BACK
    	forth 0< IF 
    		 2- HOST HERE forth OVER -  SWAP HOST TW!
    	forth ELSE 
    		DROP 
    	THEN 
    ;  TARGET


forth : +LOOP  ( n -- \ addr 3 --)
		HOST COMPILE _do_+loop
		forth BEGIN
			DUP HOST _#comp_code_leave forth =
		WHILE
			DROP
			\ still havn't added LOOP offset
			HOST HERE forth 2+ OVER -  SWAP HOST TW! forth 
		REPEAT
		\ The address points to where we want to branch back too
    	DUP ABS  HOST _#comp_code_do  ?PAIR forth OVER HOST !BACK forth
		\ The address oints after the branch so we have to 
		\ subtract 2.
    	0< IF 
    		 2- HOST HERE forth OVER -  SWAP HOST TW! forth 
    	ELSE 
    		DROP 
    	THEN 
    ;  TARGET

forth : DO    ( limit start -- \ -- addr 3 )
	HOST COMPILE _do_do  HERE _#comp_code_do
;	TARGET

forth : ?DO   ( limit start -- \ -- addr -3 )
	HOST COMPILE _do_?do zero tw,  HERE _#comp_code_?do 
;	TARGET


\ This version is used by HOST words that create child words
forth : DOES> ( --)
	\ into the host dictionary
	forth COMPILE ;code  HOST 
	HERE forth ,
	\ into the target dictionary
 \	HOST  4EB9 tw, 
	HOST
	['] _do_does> t_xt>cfa assembler AB L. JSR
	forth
	\ stop the host compile
	FALSE STATE ! 
  	\  start the target compiler. 
	HOST ]T 
 
 ;   IMMEDIATE


forth : CREATE 
	HOST
	zero ALLOT
	>IN @
	create_target_head
	DUP >IN !
	HERE t_pfa>xt 
	create_xword
	>IN !
	last @ xlast ! 
	HDS 2+ W@  HDS W!           ( Update target width)
	\ Create must keep the subcall as the call address is replaced by DOES>
	['] _do_create t_xt>cfa use
	\ This too retains a sub call so forth DOES> can modify, has
	\ to be last so , into host dictioanry is relevent.
	HERE  constant_host  

	;

HOST
	  

forth : USER  
	HOST	
	>IN @ OVER constant_host >IN ! 
	(CREATE) 
	_recover_cfa
	?DUP IF
		41EB tw,   \ ##code  3) A0 LEA
		tw,
		2D08 tw,   \ ##code A0 S -) MOV
	ELSE
		2D0B tw,   \ ##code U S -) MOV
	THEN
	4E75 tw,       \ ##code RTS
	inline      \ Tell system child word is pure code
;

HOST


\ memory area set to zero
forth : ram_here ( - a)   HOST 'tram @ ;             ( Target variable  )
forth : ram_allot ( n) 1+ 2/ 2* HOST 'tram +!    ;

forth : ram_create
	HOST ram_here CONSTANT
;

forth : ram_variable   HOST 
	HOST ram_create
	cell ram_allot 
;

forth : 2ram_variable  
	HOST ram_create
	2 CELLS ram_allot 
;

    RMEM4 'tram ! ( Start of system ram area)


\ 
forth : dictionary_variable
	HOST dictionary_here CONSTANT
	cell dictionary_allot
;

forth : dictionary_create
	HOST dictionary_here CONSTANT
;

\ MCF5307 high speed memory
forth : fast_here 
	HOST 'tfast @ 
;

forth : fast_allot ( n) 
	3+ 4/ 4* HOST 'tfast +!  
;

forth : fast_variable  
	HOST fast_here  CONSTANT 
	cell fast_allot 
;

_#rambar_base 'tfast ! ( Start of system fast ram)

#BVP5551 #BVP5552 + [IF]


	forth : static_here
		HOST 'tstatic @ 
	;

	forth : static_allot ( n) 
		3+ 4/ 4* HOST 'tstatic +!  
	;

	forth : static_variable  
		HOST static_here  CONSTANT 
		cell static_allot 
	;

	_static_ram_base 'tstatic ! ( Start of system fast ram)
[THEN]

#BVP5552 #BVP6552 + [IF]

	\ memory between cpu1 and cpu11
	forth : bank_here 
		HOST 'tbank @ 
	;

	forth : bank_allot ( n) 
		 HOST 'tbank +!  
	;

	forth : bank_create
		HOST bank_here CONSTANT
	;

	forth : bank_variable  
		HOST bank_here  CONSTANT 
		cell bank_allot 
	;

	forth : bank_wvariable  
		HOST bank_here  CONSTANT 
		2 bank_allot 
	;

	_#bank_mem_start 'tbank !

[THEN]


#BCM550h #BCM550j + #BVP5551 +  #BVP5552 + #BVP6551 + #BVP6552 + #ECM160 + [IF]
	\ RTI1000 dual port memory
	forth : port_here
		HOST 'tport @ 
	;

	forth : port_allot ( n) 1+ 2/ 2* HOST 'tport +!  ;

	forth : port_create
		HOST port_here CONSTANT
	;

	forth : port_variable
		HOST port_create
		cell port_allot 
	;

	\ history is a pain. But that is the way it is. We need this word.
	forth : port_wvariable
		HOST port_create
		2 port_allot
	;

	_#RTI1000_dual_port_base 'tport !

[THEN]

\ Immediate words are taken out of the target list and put in the immediate
\ list. This means there can be a host version that manipulates the target 
\ a target version that can be found with [COMPILE]. You will note that in the 
\ ANSI standard makes no attempt was made to specify which words were immediate. 
\ In a subroutine threaded forth many more words are immediate. As an example
\ >R and R> .
	HEX
forth : set_target_immediate_bit ( --)
	HOST
	_#immediate_bit     \ _#i(--
	target_last @       \ _#i last_target_thread(--
	@                   \ _#i last_target_lfa(--
	_t_lfa>nfa          \ _#i last_target_nfa(--
	DUP TC@             \ _#i last_target_nfa n (--
	ROT OR              \ last_targer+nfa value(--
	SWAP TC! 
;

forth : IMMEDIATE ( --)
	HOST
	set_target_immediate_bit
	to_ximmediate 
;

 
forth : [COMPILE]  ( --)
	HOST
	BL WORD 
	find_immediate IF 
		EXECUTE 
	THEN 
;   TARGET   
    


HOST

