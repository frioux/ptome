#!/usr/bin/perl -T

use strict;
use warnings;

use lib '../modules';
use TOME;
use Crypt::PasswdMD5;
use Term::Prompt;

my $username = '';
my $email = '';
my $passwd = '';

#$username = &prompt("x", "Username", "Username", '');
#$email = &prompt("x", "Email", "Email", '');
#$passwd = &prompt("p", "Password", "Password", '');

#print('Username ' . $username' . "\n" . 'Email ' . $email . "\n");

my $passwd = unix_md5_crypt('password');
my $app = TOME->new();
$app->user_add({username => 'olsonc', email => 'email', password => $passwd});

print('Success!' . "\n");
