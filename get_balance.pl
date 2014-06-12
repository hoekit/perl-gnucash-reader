#!/usr/bin/perl

use Test::More;

# Get balance of child account i.e an account without child accounts beneath
sub get_child_balance {
	my ($acct_name, $gnc_sql3) = @_;
	my $sql = <<HERE;
	'select sum(value_num) from splits where account_guid = 
	(select guid from accounts where name = "TMB Pat" 		 and parent_guid = 
	(select guid from accounts where name = "TMB" 			 and parent_guid = 
	(select guid from accounts where name = "Current Assets" and parent_guid = 
	(select guid from accounts where name = "Assets" 		 and parent_guid =
	(select guid from accounts where name = "Root Account")))));'
HERE
	return 0;
}

sub get_parent_balance {
	my ($acct_name, $gnc_sql3) = @_;
	return 0;
}


##### TESTING ##### 

my $checking_acct  = "Assets:Current Assets:Checking Account";
my $current_assets = "Assets:Current Assets";
my $gnc_sql3       = "./simple-checkbook.gnucash";

is( get_child_balance($checking_acct,  $gnc_sql3), 46, 
						'Balance of child account is correct.');
is( get_parent_balance($current_assets, $gnc_sql3), 46, 
						'Balance of parent account correct.');
done_testing(); 
