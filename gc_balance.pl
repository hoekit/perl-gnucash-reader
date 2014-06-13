#!/usr/bin/perl -w

use strict;
use GnuCashReader qw(acct_balance);

my $db = "/home/hoekit/data/GnuCash/Accounts_sql.gnucash";
die usage() unless $ARGV[0];
my $acct = $ARGV[0];

my $bal = acct_balance($acct, $db);
print $bal; print "\n";


sub usage {
	my $usage = <<HERE
USAGE:
	gc_balance.pl ACCOUNT
EXAMPLE:
	gc_balance.pl "Assets:Current Assets"
HERE
}

