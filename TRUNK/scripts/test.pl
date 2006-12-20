#!/usr/bin/perl

use strict;
use warnings;

use lib "../modules";
use TOME;
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

GetOptions (
        'username:s' => \$username,  #-u, -user, or -username, fills $username
        'password:s' => \$password,     #-p, -pass, or -password, fills $password
        'address:s' => \$address,    #-a, or -address, fills $passwd
        'port:s' => \$port,          #-port, fills $admin
	'database:s' => \$database, #-d or -database, fills $database
);

if (!$username) {
	$username = 'tome2';
}

if (!$password) {
	$password = 'tome2';
}

if (!$address) {
	$address = 'localhost';
}

if (!$port) {
	$port = '5432';
}

if (!$database) {
	$database = 'tome2';
}

print ("Blanking and re-creating database \'" . $database . "\'...\n");

$ENV{'PGPASSWORD'} = $password;
@args = ("psql", "-p", "-U", $username, "-h", $address, "-p", $port, "-d", $database, "-f", '../devdocs/clean.sql');
system (@args);
$ENV{'PGPASSWORD'} = '';

print ("\n");
print ("Beginning tests...\n");

@args = ("prove", "-r", '../tests');
system (@args);
