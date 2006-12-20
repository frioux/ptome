#!/usr/bin/perl 

use strict;
use warnings;

use lib '../modules';
use TOME;
use Crypt::PasswdMD5;
use IO::Prompt;
use Getopt::Long;

my $username = '';
my $email = '';
my $passwd = '';
my $admin = '';
my $userid = '';

GetOptions (
	'username:s' => \$username,  #-u, -user, or -username, fills $username
	'email:s' => \$email,        #-e or -email, fills $email
	'password:s' => \$passwd,    #-p, -pass, or -password, fills $passwd
	'admin' => \$admin,	     #-a or -admin, fills $admin 
);

if ($admin) {
	$admin = 'true';
} else {
	$admin = 'false';
}

if (!$username) {
	$username = prompt ("Username: ");
}

if (!$email) {
	$email = prompt ("Email: ");
}

if (!$passwd) {
	$passwd = prompt ("Password: ", -echo => '');
}

#$username = "theclint";
$passwd = unix_md5_crypt($passwd);

#print('Username ' . $username . "\n" . 'Email ' . $email . "\n");

my $app = TOME->new();
$userid = $app->user_add({username => $username, email => "admin", password => $passwd});

#print("UserID created is: \"" . $userid . "\", Admin flag is \"" . $admin . "\"\n");

$app->user_update({id => $userid, username => $username, email => "admin", notifications => 'true', admin => $admin});

print('Success!' . "\n");
