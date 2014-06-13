#!/bin/bash

# Copy to local PERL5LIB directory
if env | grep -q ^PERL5LIB=
then
	cp GnuCashReader.pm $PERL5LIB
	echo Done!
else
	echo ERROR: PERL5LIB not defined! && exit
fi
