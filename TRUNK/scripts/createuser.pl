#!/usr/bin/perl -T

use strict;
use warnings;

use lib '../modules';
use TOME;
use Crypt::PasswdMD5;
use IO::Prompt;

my $username = '';
my $email = '';
my $passwd = '';

$username = prompt ("Username: ");
$email = prompt ("Email: ");
$passwd = prompt ("Password: ", -echo => '');

#$username = &prompt("x", "Username: ", '', '');
#$email = &prompt("x", "Email: ", '', '');
#$passwd = &prompt("p", "Password: ", '', '');

#print('Username ' . $username . "\n" . 'Email ' . $email . "\n");

my $passwd = unix_md5_crypt('password');
my $app = TOME->new();
$app->user_add({username => $username, email => $email, password => $passwd});

print('Success!' . "\n");
