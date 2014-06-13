#!/bin/bash

# Copy module to local PERL5LIB directory
if env | grep -q ^PERL5LIB=
then
	cp GnuCashReader.pm $PERL5LIB
	echo Copied module.
else
	echo ERROR: PERL5LIB not defined!
fi

# Copy script to $HOME directory
if [ -d $HOME/bin ]; then
	cp gc_balance.pl $HOME/bin
	echo Copied script.
else
	echo ERROR! $HOME/bin not defined!
fi
