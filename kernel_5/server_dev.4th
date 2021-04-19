\ will end up being instance variables.
MARKER empty

\ delete the first n bytes from the start of a string
: Sdelete ( buffer size u --)
	\ limit to string length things go better
	OVER MIN \ buffer length u (--
	\ nope we are not going to allow the deletion of charaters
	\ from another dimension
	zero MAX
	>R       \ addr n(--
	.S ." addr n" CR send
	OVER     \ addr n addr (--
	R@ +   \ addr n addr_from
	.S ." add n addr_from" CR send
	jump 
	jump R@ -  \ addr n addr_from addr_to n
	.S ." addr n addr_from addr_to n" send
	MOVE     \ addr n
	+ R@ -     \ addr
	R>         \ addr count 
	.S ." addr count<--" CR
	BLANK
;	

\ insert a string at the start of string
: Sinsert ( iaddr in buffer size --)
	\ limit the string to the buffer size
	ROT        \ addr buffer size n
	OVER       \ addr buffer size n size
	MIN        \ addr buffer size min
	>R         \ addr buffer size 
	R@ -       \ addr buffer cnt_left
    OVER       \ addr buffer cnt_letf buffer
    DUP R@ +   \ addr buffer cnt_left buffer beffer_to	
	ROT MOVE   \ addr buffer
	R> MOVE 
;

\ $ we have in use to descibe a string stored with a byte count at the start.
\ $ strings get heavy use in the kernel; as a sting for word names as an example.
\ We will give this new type of string a new name "string" sounds good.
\ A string stores the address of a data structure, the data structire has the form.
zero 
DUP CONSTANT _#string_count CELL+
DUP CONSTANT _#string_data  DROP


\ The will use data areas taken and returned to the heap.
: string! ( addr1 u string --)
	DUP @ IF 
		DUP @ FREE THROW
		\ set to zero we could ABORT and the data structure must
		\ reflect what we have done 
		zero OVER !
	THEN
	OVER CELL+ ( room for the count) ALLOCATE THROW \ addr n addr2 addr2
	>R
	R@ SWAP !
	DUP R@ _#string_count + !  \ save count
	R> _#string_data + SWAP MOVE
;

\ chande the string  to S ( that is the data address and count
: string@ ( string -- addr u )
	@ DUP _#string_data + SWAP _#string_count + @ 
;

: string@len ( string --len)
	@ _#string_count + @
;

\ set the string to a new length; this could involve the reallocation of the stings
\ area
: string!len ( u string --)
	OVER           \ u string u
	OVER @         \ u string u addr 
	SWAP           \ u string addr u 
	RESIZE THROW   \ u string addr
	OVER !         \ u string
	@ _#string_count + !            \
;

\ delete u bytes at offset 
: string_del { ( string ) variable %offset variable %u ( --) }
	DUP string@ %offset @ 
	/STRING                  \ string add n (--
	%u @ Sdelete              \ string(--
	DUP string@len %u @ -    \ string new_len(--
	SWAP string!len 
;

\ insert S at offset
: string_insert { ( addr1 u ) variable %string variable %off (  --) }
	DUP %string @ string@len + %string @ string!len 
	string@  \ addr n buffer n1
	%off @ /STRING
	Sinsert 
;

\ add S to end
: string+! ( addr u string --)
	DUP string@len string_insert
;

\ release a string
: string_return ( string --)
	DUP @ FREE THROW
	zero SWAP !
;
</code>
\ -----------------------------------------------------------------------
\ start of server code
\ -----------------------------------------------------------------------
ram_variable %%url
ram_variable %%posted
ram_variable %%url_args
ram_variable %%protocol

\ request_line = method SP Request-URI SP HTTP-Version CRLF
\ the read will look afer turning CRLPSP back into spaces.
\ The spec is quit clear that the seperator is a SP. We will accecpt LWS
\ it makes it simple for us as the read can then convert all LWS into space.
\
\ take token that ends in the defined character from the input stream; remove leading
\ and trailing white space.
: get_token ( char -- addr num)	
	PARSE \ addr addr1 num(--
	-TRAILING
	-leading
;

\ convert %xx to number and store as character
\ As the resultant string will be shorter 
\ we go from left to right converting the data and moving data from above down.
\ The COLDFORTH TIB in read writable so we do it there
\
\ Looks very portable with all those CHARS; it's actually wrong; we are dealing
\ with netwrok caracters here; CHARS is talking about local characters.
\ I think this highlights just how nmessy thngs get when ytou break the 
\ char = 8 bit assumption.
\
\ The % conversion is in HEX; lower and upper case charcters are valid.
\
\ code assumes string can be written
: rework% { variable %addr variable %num ( -- addr num) }
	BASE @ >R HEX \ addr num (--
	%addr @
	%num @
	BEGIN
		DUP
	WHILE
		OVER char@ [CHAR] % = IF
			OVER 1 CHARS + 2 Snumber  \ addr num data (--
			jump char!                \ addr num
			\ now move everything down 2 charaters
			\ everything is the current count less three
			OVER 3 CHARS +            \ addr num from (--
			jump 1 CHARS +            \ addr num from to (--
			jump 3 - CHARS            \ addr num from to length(--
			MOVE
			SWAP 1 CHARS +
			SWAP 3 -                  \ addr num (--
			\ string is now shorter by two characters.
			-2 %num +!
		ELSE
			SWAP 1 CHARS +
			SWAP 1 -
		THEN
	REPEAT
	R> BASE !
	%addr @ %num @
;

WORDLIST CONSTANT &html_commands
WORDLIST CONSTANT &html_headers
WORDLIST CONSTANT &mime_types

\ We need to be carefull with the header fields.
\ convention has it
\ name: value
\ Nowhere in the spec doesn't say it can't be 
\ name:value
\ for example the accept BNF is:
\ "Accept" ":" *( media-range [ accept-params ])
\ Nothing in there to say there is no white space before the : and there is white
\ space after.
\ On page 15 of RFC2612 it states quite clearly that LWS can exist between quoted
\ strings. It is only required between two tokens.
\ Useing them rules the convention is allowed along with several other options.
\ 
\ I think we are best to split at the : then remove leading and trailing white space.
\ Having made this choice INTERPRET can't be used; but that would only be a big deal 
\ to FORTH purists.
\
: header_name ( -- addr n )
	[CHAR] : get_token
;


\
\ We must remember that this is going to be a multithreaded server. The header names 
\ can exist to let us know what we support. The actually return an offset into a
\ table. The table resides in the object. 
\
\ Why are we going to be multihreaded.
\ 1) So I can copy telnet server code; it has to be multithreaded.
\ 2) Active content can include the taking of pictures; that should be multithreaded.
\

CREATE _header_table_length 0 ,

: header: CREATE  _header_table_length @ , 4 _header_table_length +! DOES> @ ;

ALSP &html_headers context !
DEFINITIONS

header: User-Agent
header: Pragma
header: Host
header: Accept
header: Accept-Encoding
header: Accept-Language
header: Accpet-Charset
header: Via
header: X-Forward-For
header: Cache-Control
header: Connection
header: Referer
Header: Content-Type
Header: Control-Length
	
previous_definitions
 
ram_variable %%header_table _header_table_length ram_allot

\ addr is the base address of our table
: save_header ( addr --)
	header_name DUP IF
		&html_headers SEARCH-WORDLIST IF
			EXECUTE 
			+         \ addr(--
			\ make sure old string is returned.
			DUP _return_old_string
			\ we have prepocessed string #CR end the record.
			#cr get_token
		ELSE
			\ we don't know what was said.
			\ ####
		THEN
	ELSE
		\ there was no :
		\ ####
	THEN
;

\ you keep getting headers until you see an empty line.
\ We should not get to the end of the file
: get_headers ( --)
	BEGIN 
		REFILL
	WHILE
		SOURCE NIP IF
			\ headers are done
			EXIT
		THEN
		\ ok do our stuff 
		save_header
	REPEAT
	\ this is an error the request was not terminated with an empty line
	\ the connection was closed instead. Best to just give up
	\ #####
;

\ change search order to value wordlist
: >headers ( --)
	&html_headers 1 SET-ORDER FASLE %commands ! ;

\ This is the way it should be the data gets moved after we have worked out
\ what to do.	
: get_request_line ( --)
	\ the url
	BL get_token \ addr1 num(--
	\ convert %xx to characters
	rewordk% \ addr1 num2(--
	\ find the ?
	2DUP [CHAR] ? Sparse \ addr1 num1  addr2 num2
	\ if num1 and num2 are equal then no ?
	jump OVER = IF
		\ all the rting is the URL
		2DROP %url !string
	ELSE
		>R R@
		\ first string is URL
		%url !string
		\ second string is after first
		SWAP R@ + 1 CHARS + SWAP R> - 1 - %url_args !string
	THEN 
	BL get_token %protocol !
;


ALSO &mime_types context !
DEFINITIONS
\ for a full list see etc/mime.types on a linux system.
\ This only contains types we are likly to serve.
\ The word name is the file extension; the string hase to be sent out
\ as Content-Type:
CREATE txt ," text/plain"
CREATE gif ," image/gif"
CREATE html ," text/html"
CREATE htm  ," text/html"
CREATE jpeg ," image/jpeg"
CREATE png  ,' image/png" 
previous_definitions


: .server ." Server: COLDFORTH httpd/0.1 (" .version ." )" CR ;

\ Status_line = HTTP-Version SP Status_code SP Reason_string
: Status_line ( n addr u --)
	." HTTP/1.1 " ROT .d TYPE 
;


\ see section 5.2 rfc 2616 page 38
\ a URL should come in the form
\ Page 19 section 3.2.2
\ http_URL = "http:" "//" host [ ":" port ] [ abs_path [ "?" query ] ]
\
\ Page 36
\ Request-URI = "*" | absolutURL | abs_path | authority
\ 
\ Or in other words the spec is not consistant. I think we can assume REquest-URl 
\ = absolutUR
\
\ All this makes sense if we are serving multiple host.
\
\ We can also get it in the form
\ /file
\ If in this form we may have a host: header.
\
\ If we get / we supply the file index.html
\
\ Section 19.6.1.1 says we should get upset if the client speaking 1.1
\ doesn't supply the host:
\
\ This is an embedded server. lets keep it simple.
\
\ address points to a free buffer containeing a counted string
: find_file ( addr --)
	\ strip of the http: if present.
	@ COUNT left_split \ addrl nl addrr lenr
	\ if there was to : all the data is still in the left string
	DUP not IF
		\ no http:
	ELSE
		\ ok make sure it is http
		2SWAP
		$http COUNT COMPARE 0= not IF
			\ error condition url started with something other than http:
		ELSE
			\ strip the leading :
			[CHAR] : remove_leading
			\ we now have \\host\file
			DUP 2 > IF
				OVER char@ [CHAR] / =            \ addr num flag(--
				jump 1 CHARS + CHAR@ [CHAR] / =  \ addr num flag flag(--
				AND                              \ addr num flag(-- 
				IF
					\ this will accept 2 or more
					[CHAR] \ remove_leading
					[CHAR] \ left_split		
	






ALSO &html_commands context !
DEFINITIONS

: GET  ( -- ) 	\ 
				\ %url
				\ %url_args
				get_reguest_line 
				>headers get_headers send_request reset_headers;
: POST ( -- ) get_request_line >headers get_headers post_data reset_headers;
: HEAD ( -- ) get_request_line >headers get_headers send_requested_head reset_headers;

previous_definitons 
<code>


 
 