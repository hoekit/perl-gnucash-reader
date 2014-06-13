#!/usr/bin/perl -w

use GnuCashReader ('acct_balance', 'run_sql', 'gen_sql', 'get_child_balance',
				   'leaf_guid_balance', 'guid_sql', 'get_guid', 'child_guids',
				   'is_leaf_guid', 'is_leaf_account', 'guid_balance');
use strict;
use Test::More;

my $acct;
my $db = "./simple-checkbook2.gnucash";
my $sql;
my ($guid,$res_guid);
my @guids;

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
$res_guid = "53f15dbd44e778d1f48efb53e6df0fa2".
				"|a2607fd7e4b67fe9e8fc8421841e91de";
@guids = child_guids($guid,$db);
is( join("|",@guids), $res_guid,
	'child_guids() works.');

$guid = "53f15dbd44e778d1f48efb53e6df0fa2";
$res_guid = "14d772a027f4bfed77d39362989b87b6";
@guids = child_guids($guid,$db);
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

$acct = "Assets:Current Assets:Checking Account";
$guid = "14d772a027f4bfed77d39362989b87b6";
is( guid_balance($guid, $db, 0), 4600, 
	'guid_balance($guid,$db) works.');

$guid = "9fc6b68385116caba4611d1440fa6a24";
is( guid_balance($guid, $db, 0), 104600, 
	'guid_balance($guid,$db) works.');

$acct = "Assets";
is( acct_balance($acct, $db, 0), 104600, 
	'acct_balance($acct,$db) works.');

$acct = "Assets:Current Assets:Checking Account";
is( acct_balance($acct, $db, 0), 4600, 
	'acct_balance($acct,$db) works.');


done_testing(); 
exit;

