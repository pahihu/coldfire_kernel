\ if we queue a packet for destination 127.000.000.000 it will be sent to our virgin
\ software.
\ We are now testing tcp_dequeue.
\ 

		: _setup_tcp_packet { ( seq rcv.wnd rcv.nxt ) variable %flags variable %pep -- }
			0 \ %%local_machine @ 
			127.0.0.0 \ %%remote_machine @ 
			0 \ option length
			%pep @ 
			setup_ip
			\ set tcp protocol
			IPT_TCP %pep @ ep_data + ip_proto + B!

			#tcp_header_end %pep @ add_to_ip
			%pep @ ep_ipdata + @ 
			$123 \ %%local_port @	
			OVER #tcp_src + W!
			$456 \ %%remote_port @ 
			OVER #tcp_dst + W!
			SWAP OVER #tcp_ack + !
			\ snd.una rcv.wnd ip_data(--
			SWAP OVER #tcp_window + W!
			\ snd.una ip_data(--
			SWAP OVER #tcp_seq + !
			\ ip_data(--
			[ #tcp_header_end 2 RSHIFT ( to 32 bit words) 4 LSHIFT 
			( top 4 bits ) ] LITERAL
			OVER #tcp_offset + B!
			\ ip_data(--
			%flags @ OVER #tcp_flags + B!
			\ ip_data(--
			zero OVER #tcp_urgptr + W!
			\ ip_data(--
			%pep @ ep_ipdata + @ #tcp_header_end + %pep @ ep_protodata + !
			zero %pep @ ep_protocount + !
			\ the protocol object for checksum latter in the datgrams life.
			_%tcp_object @ %pep @ ep_proto_obj + !
			\ ipdata(--
			DROP
		;

		: _add_to_tcp ( n  pep  -- ) 
			2DUP add_to_ip
			ep_protocount + +!
		;
			


: sp  { ( --) }{
		variable %pep
	}
	$80 get_free_buffer 
	.S
	%pep !
	%pep @ 80 ERASE
	$100 $200 $300 0 %pep @ 	
	_setup_tcp_packet
	%pep @ $80 DUMP
	%pep @
;






