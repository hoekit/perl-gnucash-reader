#!/usr/bin/perl -w

package GnuCashReader;
use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = ('acct_balance', 'guid_balance', 'get_guid', 
			  'run_sql', 'acct_bal_sql', 'leaf_guid_balance',
			  'guid_sql', 'child_guids', 'is_leaf_guid', 'is_leaf_account' );

#### Exported functions ####

# Given: an SQL statement, an sqlite database file
#   Return: result of running the SQL statement
sub run_sql {
	my ($sql,$db) = @_;
	# TODO: croak if sqlite database file not found.
	my $cmd = "sqlite3 $db '$sql;'";
	#print $cmd."\n";
	my $res = `$cmd`; chomp $res;
	return $res;
}

# Given: an account name in full e.g. "Assets:Current Assets",
#   Return an sql statement that computes the balance of that account.
sub acct_bal_sql {
	my ($acct_name) = @_;
	my $sub_sql = guid_sql($acct_name);
	return  "select sum(value_num) from splits ".
			" where account_guid = ($sub_sql)";
}

sub leaf_guid_balance {
	my ($guid,$db) = @_;
	my $sql = 'select sum(value_num) from splits '.
				'where account_guid = "'.$guid.'"';
	my $result = run_sql($sql,$db);
	return $result eq "" ? 0 : $result;
}

sub guid_sql {
	my ($acct_name) = @_;
	my $sub_sql = 'select guid from accounts where name = "Root Account"';
	foreach my $acct (split ":", $acct_name) {
		$sub_sql = 'select guid from accounts'
					.' where name = "'.$acct.'"'
					.' and parent_guid = ('.$sub_sql.')';
	}
	return $sub_sql;
}

sub get_guid {
	my ($acct,$db) = @_;
	return run_sql(guid_sql($acct),$db);
}

sub child_guids {
	my ($guid,$db) = @_;
	my $sql = 'select guid from accounts where parent_guid = "'.$guid.'"';
	my $result = run_sql($sql,$db);
	return split("\n",$result);
}

sub is_leaf_guid {
	my ($guid,$db) = @_;

	# Get list of accounts with that as parent guid
	my $sql = 'select guid from accounts where parent_guid = "'.$guid.'"';
	my $result = run_sql($sql,$db);
	my @child_guid = split("/n",$result);

	# return TRUE if list of child accounts is empty
	$#child_guid == -1 ? 1 : 0;
}

# Returns TRUE if account has no child accounts
sub is_leaf_account {
	my ($acct,$db) = @_;
	# Get account guid
	my $guid = run_sql(guid_sql($acct),$db);

	# Get list of accounts with that as parent guid
	my @child_guid = child_guids($guid,$db);

	# return TRUE if list of child accounts is empty
	$#child_guid == -1 ? 1 : 0;
}

sub guid_balance {
	my ($guid,$db,$balance) = @_;

	# Add balances in child accounts if any
	my $child_balance = 0;
	foreach my $g (child_guids($guid,$db)) {
		$balance += guid_balance($g,$db,$child_balance);
	}
	
	# Add balance in parent account
	return $balance + leaf_guid_balance($guid,$db);
}

sub acct_balance {
	my ($acct,$db) = @_;
	return guid_balance( get_guid($acct,$db), $db, 0)/100;
}


#### UnExported functions ####

1;
