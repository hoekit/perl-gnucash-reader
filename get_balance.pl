#!/usr/bin/perl

use strict;
use Test::More;

# Get balance of child account i.e an account without child accounts beneath
sub get_child_balance {
	my ($acct_name, $db) = @_;

	# Generate sql
	my $sql = gen_sql("Assets:Current Assets:Checking Account");

	# Run sql
	run_sql($sql,$db);
}

sub gen_sql {
	my ($acct_name) = @_;
	my $sub_sql = '(select guid from accounts where name = "Root Account")';
	foreach my $acct (split ":", $acct_name) {
		$sub_sql = '(select guid from accounts'
					.' where name = "'.$acct.'"'
					.' and parent_guid = '.$sub_sql.')';
		#print $sub_sql."\n";
	}
	return  "select sum(value_num) from splits ".
			" where account_guid = $sub_sql;";
}

sub run_sql {
	my ($sql,$db) = @_;
	my $cmd = "sqlite3 $db '$sql'";
	#print $cmd."\n";
	my $res = `$cmd`; chomp $res;
	return $res;
}

sub get_parent_balance {
	my ($acct_name, $gnc_sql3) = @_;
	return 0;
}


##### TESTING ##### 

my $acct;
my $gnc_sql3       = "./simple-checkbook.gnucash";
my $sql;

$sql = "select 10;";
is( run_sql($sql,$gnc_sql3), "10");

$sql = "select count(*) from versions;";
is( run_sql($sql,$gnc_sql3), "24");

$sql = 'select guid from accounts where name = "Root Account"';
is( run_sql($sql,$gnc_sql3), "7a083dd7a0ac1c4aa0c3c5cd2b291769");

$sql = <<HERE;
select guid from accounts where name = "Current Assets"  and parent_guid = 
(select guid from accounts where name = "Assets" 		 and parent_guid = 
(select guid from accounts where name = "Root Account"));
HERE
is( run_sql($sql,$gnc_sql3), "53f15dbd44e778d1f48efb53e6df0fa2");

$sql = <<HERE;
select guid from accounts where name = "Checking Account" and parent_guid = 
(select guid from accounts where name = "Current Assets"  and parent_guid = 
(select guid from accounts where name = "Assets" 		 and parent_guid = 
(select guid from accounts where name = "Root Account")));
HERE
is( run_sql($sql,$gnc_sql3), "14d772a027f4bfed77d39362989b87b6");

$sql = 'select sum(value_num) from splits  where account_guid = (select guid '
.'from accounts where name = "Checking Account" and parent_guid = (select guid '
.'from accounts where name = "Current Assets" and parent_guid = (select guid '
.'from accounts where name = "Assets" and parent_guid = (select guid from '
.'accounts where name = "Root Account"))));';
is( gen_sql("Assets:Current Assets:Checking Account"), $sql);

$acct = "Assets:Current Assets:Checking Account";
is( get_child_balance($acct, $gnc_sql3), 4600, 
	'Balance of child account is correct.');

$acct = "Assets:Current Assets";
is( get_parent_balance($acct, $gnc_sql3), 4600, 
	'Balance of parent account correct.');

done_testing(); 
