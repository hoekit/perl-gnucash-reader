#!/usr/bin/perl

use strict;
use warnings;
use GnuCashReader qw(acct_balance get_guid);
use Path::Tiny qw( path ); # See http://perlmaven.com/slurp 

my $db = "/home/hoekit/data/GnuCash/Accounts_sql.gnucash";
die usage() unless $ARGV[0];

# read conditions from file
my $cond_file = $ARGV[0];
my @cond = split("\n",path($cond_file)->slurp);

# for each condition
foreach my $c (@cond) {
	# extract account name and condition
	my ($acct, $cond) = $c =~ /^\s*"(.*)"\s*(.*)/;
	#print "Acct: $acct; Condition: $cond\n";

	# if account exists...
	if (exist_acct($acct)) {
		# get account balance and check condition
		my $bal = acct_balance($acct,$db);
		my $match = eval("$bal $cond");
		print $c." | $bal\n" if $match;
	} else {
		# print error message
		print err_missing($acct)."\n";
	}
}

sub exist_acct {
	my ($acct) = @_;
	my $guid = get_guid($acct,$db);
	return $guid eq "" ? 0 : 1;
}

sub err_missing {
	my ($acct) = @_;
	return "ERROR: \"$acct\" not found!";
}

sub usage {
	my $usage = <<HERE

USAGE:
	gc_check.pl <FILE>
EXAMPLE:
	gc_check.pl checks.txt

DETAILS:
	FILE: Has following format:

		"Account1" <CONDITION1>
		"Account2" <CONDITION2>

	EXAMPLE - 

		"Assets:Current Assets:Checking Account" > 1000
		"Assets:Current Assets:" <= 1000

HERE
}

