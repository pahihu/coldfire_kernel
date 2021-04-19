\ <a HREF="./license.html">license</a>
\ Most of the file represents comments, nice comments but comments
\ we just want the stuff between <code> and </code>. 
\ This will be contained within <html> </html>
\
\ So really the whole thing is a piece of cake. <html> 
\ is a comment starter
\ <code> a comment ender. </code> a comment starter and 
\ </html> a comment ender.
\ Not much really for pretty code presentation is it.
\ Has to be in a non html file as names can cause problems
\
	: <html>  ( -- )
		BEGIN                                    
			BEGIN
				BL (word) DUP  
			WHILE                                
				2DUP  S" </html>"  COMPARE 
				0= IF                             
					2DROP                        
					EXIT
				THEN                              
				2DUP  S" <code>"  COMPARE 
				0= IF                               
					2DROP                        
					EXIT
				THEN                              
				2DROP
			REPEAT  2DROP                           
		REFILL 0=  UNTIL                          
	;  IMMEDIATE
	

	: </code>  ( -- )
		BEGIN                                    
			BEGIN
				BL (word) DUP  
			WHILE                                
				2DUP  S" </html>"  COMPARE 
				0= IF                             
					2DROP                        
					EXIT
				THEN                              
				2DUP  S" <code>"  COMPARE 
				0= IF                               
					2DROP                        
					EXIT
				THEN                              
				2DROP
		  REPEAT  2DROP                           
		REFILL 0=  UNTIL                          
	;  IMMEDIATE

	: <HTML>  ( -- )
		BEGIN                                    
			BEGIN
				BL (word) DUP  
			WHILE                                
				2DUP  S" </HTML>"  COMPARE 
				0= IF                             
					2DROP                        
					EXIT
				THEN                              
				2DUP  S" <CODE>"  COMPARE 
				0= IF                               
					2DROP                        
					EXIT
				THEN                              
				2DROP
			REPEAT  2DROP                           
		REFILL 0=  UNTIL                          
	;  IMMEDIATE
	

	: </CODE>  ( -- )
		BEGIN                                    
			BEGIN
				BL (word) DUP  
			WHILE                                
				2DUP  S" </HTML>"  COMPARE 
				0= IF                             
					2DROP                        
					EXIT
				THEN                              
				2DUP  S" <CODE>"  COMPARE 
				0= IF                               
					2DROP                        
					EXIT
				THEN                              
				2DROP
		  REPEAT  2DROP                           
		REFILL 0=  UNTIL                          
	;  IMMEDIATE


	: <!DOCTYPE  ( -- )
		BEGIN                                    
			[CHAR] ) (word) 2DROP TIB  >IN @ + 1- C@ [CHAR] > = IF
				EXIT
			THEN 
			REFILL 0=  
		UNTIL                          
	;  IMMEDIATE
	


