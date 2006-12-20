#!/usr/bin/perl

use strict;
use warnings;

use lib "../modules";
use TOME;
use Crypt::PasswdMD5;
use IO::Prompt;
use DBI;
use IO::File;

my $address = '';
my $port = '';
my $username = '';
my $password = '';
my $database = '';

GetOptions (
        'username:s' => \$username,  #-u, -user, or -username, fills $username
        'password:s' => \$password,     #-p, -pass, or -password, fills $password
        'address:s' => \$serveraddress,    #-a, or -address, fills $passwd
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

