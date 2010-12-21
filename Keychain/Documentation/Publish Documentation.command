#!/bin/tcsh

if ( ! -e Documentation ) then
	./Generate\ Documentation.command
endif

rsync -vzr --delete --delete-after --stats --progress --rsh="ssh -l wadetregaskis" Documentation/Public wadetregaskis@shell.sourceforge.net:/home/groups/k/ke/keychain/htdocs/Documentation
rsync -vzr --delete --delete-after --stats --progress --rsh="ssh -l wadetregaskis" Documentation/Private wadetregaskis@shell.sourceforge.net:/home/groups/k/ke/keychain/htdocs/Documentation
