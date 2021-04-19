.( we are loading a file )

0x0FF000000 CONSTANT _#Version_number

        : Wait_fpga_running ( -- )
                BEGIN
                        _#Status_Register @ _#Version_number AND
                        _#Version_number = NOT
                UNTIL
        ;



