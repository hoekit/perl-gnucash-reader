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

sub leaf_guid_balance {
	my ($guid,$db) = @_;
	my $sql = 'select sum(value_num) from splits '.
				'where account_guid = "'.$guid.'"';
	return run_sql($sql,$db);
}


sub gen_sql {
	my ($acct_name) = @_;
	my $sub_sql = guid_sql($acct_name);
	return  "select sum(value_num) from splits ".
			" where account_guid = ($sub_sql)";
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

sub run_sql {
	my ($sql,$db) = @_;
	my $cmd = "sqlite3 $db '$sql;'";
	#print $cmd."\n";
	my $res = `$cmd`; chomp $res;
	return $res;
}

sub guid_balance {
	my ($guid,$db,$balance) = @_;

	# Get list of child accounts
	foreach my $g (child_guids($guid,$db)) {
		# If child account is leaf, get_child_balance for leaf account
		if (is_leaf_guid($g,$db)) {
			$balance += leaf_guid_balance($g,$db);
		} else {
			# If child account not leaf, recursively call guid_balance
			$balance += guid_balance($g,$db,$balance);
		}
	}
	return $balance;
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

sub is_leaf_guid {
	my ($guid,$db) = @_;

	# Get list of accounts with that as parent guid
	my $sql = 'select guid from accounts where parent_guid = "'.$guid.'"';
	my $result = run_sql($sql,$db);
	my @child_guid = split("/n",$result);

	# return TRUE if list of child accounts is empty
	$#child_guid == -1 ? 1 : 0;
}

sub child_guids {
	my ($guid,$db) = @_;
	my $sql = 'select guid from accounts where parent_guid = "'.$guid.'"';
	my $result = run_sql($sql,$db);
	return split("\n",$result);
}

##### TESTING ##### 

my $acct;
my $db = "./simple-checkbook2.gnucash";
my $sql;
my $guid;

$sql = "select 10;";
is( run_sql($sql,$db), "10",
	'run_sql() works.');

$sql = "select count(*) from versions;";
is( run_sql($sql,$db), "24",
	'run_sql() works.');

$sql = 'select guid from accounts where name = "Root Account"';
is( run_sql($sql,$db), "7a083dd7a0ac1c4aa0c3c5cd2b291769",
	'run_sql() works.');

$sql = <<HERE;
select guid from accounts where name = "Current Assets"  and parent_guid = 
(select guid from accounts where name = "Assets" 		 and parent_guid = 
(select guid from accounts where name = "Root Account"));
HERE
is( run_sql($sql,$db), "53f15dbd44e778d1f48efb53e6df0fa2",
	'run_sql() works.');

$sql = <<HERE;
select guid from accounts where name = "Checking Account" and parent_guid = 
(select guid from accounts where name = "Current Assets"  and parent_guid = 
(select guid from accounts where name = "Assets" 		 and parent_guid = 
(select guid from accounts where name = "Root Account")));
HERE
is( run_sql($sql,$db), "14d772a027f4bfed77d39362989b87b6",
	'run_sql() works.');

$sql = 'select sum(value_num) from splits  where account_guid = (select guid '
.'from accounts where name = "Checking Account" and parent_guid = (select guid '
.'from accounts where name = "Current Assets" and parent_guid = (select guid '
.'from accounts where name = "Assets" and parent_guid = (select guid from '
.'accounts where name = "Root Account"))))';
is( gen_sql("Assets:Current Assets:Checking Account"), $sql,
	'gen_sql() works.');

$acct = "Assets:Current Assets:Checking Account";
is( get_child_balance($acct, $db), 4600, 
	'get_child_balance() works.');

$acct = "Assets:Current Assets:Checking Account";
$guid = "14d772a027f4bfed77d39362989b87b6";
is( leaf_guid_balance($guid, $db), 4600, 
	'leaf_guid_balance() works.');

$acct = "Assets:Current Assets";
$sql = 'select guid from accounts where name = "Current Assets" and parent_guid = (select guid from accounts where name = "Assets" and parent_guid = (select guid from accounts where name = "Root Account"))';
is( guid_sql($acct), $sql,
	"guid_sql() works.");

$acct = "Assets:Current Assets:Checking Account";
$guid = "14d772a027f4bfed77d39362989b87b6";
is( get_guid($acct,$db), $guid,
	'get_guid() works.');

$guid = "9fc6b68385116caba4611d1440fa6a24";
my $res_guid = "53f15dbd44e778d1f48efb53e6df0fa2".
				"|a2607fd7e4b67fe9e8fc8421841e91de";
my @guids = child_guids($guid,$db);
is( join("|",@guids), $res_guid,
	'child_guids() works.');

$guid = "53f15dbd44e778d1f48efb53e6df0fa2";
my $res_guid = "14d772a027f4bfed77d39362989b87b6";
my @guids = child_guids($guid,$db);
is( join("|",@guids), $res_guid,
	'child_guids() works.');

$guid = "14d772a027f4bfed77d39362989b87b6";
is( is_leaf_guid($guid,$db), 1,
	'is_leaf_guid() works.');

$guid = "53f15dbd44e778d1f48efb53e6df0fa2";
is( is_leaf_guid($guid,$db), 0,
	'is_leaf_guid() works.');

$acct = "Assets:Current Assets:Checking Account";
is( is_leaf_account($acct,$db), 1,
	'is_leaf_account() works.');

$acct = "Assets:Current Assets";
is( is_leaf_account($acct,$db), 0,
	'is_leaf_account() works.');

$acct = "Assets:Current Assets";
$guid = "53f15dbd44e778d1f48efb53e6df0fa2";
is( guid_balance($guid, $db, 0), 4600, 
	'guid_balance($guid,$db) works.');

$acct = "Assets";
$guid = "9fc6b68385116caba4611d1440fa6a24";
is( guid_balance($guid, $db, 0), 104600, 
	'guid_balance($guid,$db) works.');

done_testing(); 
exit;

