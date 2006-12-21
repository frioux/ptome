#!/usr/bin/perl

use strict;
use warnings;

use lib "../modules";
use lib "../testclasses";
#use TOME;
use TOMETest;
use Crypt::PasswdMD5;
use IO::Prompt;
use DBI;
use IO::File;
use Getopt::Long;

my $address = '';
my $port = '';
my $username = '';
my $password = '';
my $database = '';
my @args = '';

my $tst = TOMETest->new();
my %config = %{$tst->{config}};

$address = $config{'dbihostname'};
$port = $config{'dbiport'};
$database = $config{'dbidbname'};
$username = $config{'dbiusername'};
$password = $config{'dbipassword'};

GetOptions (
        'username:s' => \$username,  #-u, -user, or -username, fills $username
        'password:s' => \$password,     #-p, -pass, or -password, fills $password
        'address:s' => \$address,    #-a, or -address, fills $passwd
        'port:s' => \$port,          #-port, fills $admin
	'database:s' => \$database, #-d or -database, fills $database
);

#$ENV{'TOMEUSERNAME'} = $username;
#$ENV{'TOMEPASSWORD'} = $password;
#$ENV{'TOMEDBADDRESS'} = $address;
#$ENV{'TOMEDBPORT'} = $port;
#$ENV{'TOMEDBNAME'} = $database;

print ("Blanking and re-creating database \'" . $database . "\'...\n");

$ENV{'PGPASSWORD'} = $password;
@args = ("psql", "-p", "-U", $username, "-h", $address, "-p", $port, "-d", $database, "-f", '../devdocs/clean.sql', "-o", '/dev/null', "--variable", 'VERBOSITY=terse');
system (@args);
$ENV{'PGPASSWORD'} = '';

print ("\n");
print ("Beginning tests...\n");

@args = ("prove", "-rv", '../tests');
system (@args);

#$ENV{'TOMEUSERNAME'} = '';
#$ENV{'TOMEPASSWORD'} = '';
#$ENV{'TOMEDBADDRESS'} = '';
#$ENV{'TOMEDBPORT'} = '';
#$ENV{'TOMEDBNAME'} = '';

