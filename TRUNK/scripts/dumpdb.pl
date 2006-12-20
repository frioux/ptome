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
my $dump = '';

GetOptions (
        'username:s' => \$username,  #-u, -user, or -username, fills $username
        'password:s' => \$password,     #-p, -pass, or -password, fills $password
        'address:s' => \$address,    #-a, or -address, fills $passwd
        'port:s' => \$port,          #-port, fills $admin
        'database:s' => \$database, #-d or -database, fills $database
);

if (!$username) {
	$username = prompt ("Username: ", -default => 'tome');
}

if (!$password) {
	$password = prompt ("Password: ", -echo => '');
}

if (!$address) {
	$address = prompt ("Address: ", -default => 'localhost');
}

if (!$port) {
	$port = "5432";
}

if (!$database) {
	$database = prompt ("Database name: ", -default => 'tome');
}

$ENV{'PGPASSWORD'} = $password;
$dump = `pg_dump --no-owner -h $address -p $port -U $username $database`;
$ENV{'PGPASSWORD'} = '';

print ($dump);
