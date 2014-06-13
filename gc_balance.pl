#!/usr/bin/perl -w

use strict;
use GnuCashReader qw(acct_balance get_guid);

my $db = "/home/hoekit/data/GnuCash/Accounts_sql.gnucash";
die usage() unless $ARGV[0];
my $acct = $ARGV[0];

#print $acct."\n"; 
#print get_guid($acct, $db)."\n"; 

my $bal = acct_balance($acct, $db, 0);
print $bal/100; print "\n";


sub usage {
	my $usage = <<HERE
USAGE:
	gc_balance.pl ACCOUNT
EXAMPLE:
	gc_balance.pl "Assets:Current Assets"
HERE
}

