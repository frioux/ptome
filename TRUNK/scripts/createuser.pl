#!/usr/bin/perl -T

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

GetOptions (
	'username:s' => \$username,  #-u, -user, or -username, fills $username
	'email:s' => \$email,        #-e or -email, fills $email
	'password:s' => \$passwd,    #-p, -pass, or -password, fills $passwd
);

if (!$username)
{
  $username = prompt ("Username: ");
}

if (!$email)
{
  $email = prompt ("Email: ");
}

if (!$passwd)
{
  $passwd = unix_md5_crypt(prompt ("Password: ", -echo => ''));
}

#$username = &prompt("x", "Username: ", '', '');
#$email = &prompt("x", "Email: ", '', '');
#$passwd = &prompt("p", "Password: ", '', '');

#print('Username ' . $username . "\n" . 'Email ' . $email . "\n");

#my $passwd = unix_md5_crypt('password');
my $app = TOME->new();
$app->user_add({username => $username, email => $email, password => $passwd});

print('Success!' . "\n");
