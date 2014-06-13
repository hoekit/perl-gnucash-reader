#!/usr/bin/perl

use strict;
use warnings;
use GnuCashReader qw(acct_balance get_guid);
use Path::Tiny qw( path ); # See http://perlmaven.com/slurp 

my $db = $ENV{"HOME"}."/data/GnuCash/Accounts_sql.gnucash";
my $DEF_COND_FILE = $ENV{"HOME"}."/.gc_checks.txt";

# read conditions from file
my $cond_file = get_cond_file();
my @cond = split("\n",path($cond_file)->slurp);

# for each condition
foreach my $c (@cond) {
	# extract account name and condition
	next if $c =~ /^\s*$/;
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

# Read from $HOME/.gc_checks.txt if it exists
# Otherwise read from $ARGV[0]
# Otherwise raise an error
sub get_cond_file {
	if (defined($ARGV[0])) {
		return $ARGV[0];
	} elsif ( path($DEF_COND_FILE)->exists ) {
		return $DEF_COND_FILE;
	} else {
		die usage();
	}
}


