: kdiff ( --)
	$80000 0 DO
		I @ I $2C00000 + @ <> IF
			I . SPACE
		THEN
		^C
	4 +LOOP
;
