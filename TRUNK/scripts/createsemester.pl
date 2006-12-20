#!/usr/bin/perl 

use strict;
use warnings;

use lib '../modules';
use TOME;
use Crypt::PasswdMD5;
use IO::Prompt;
use Getopt::Long;

my $semestername = '';
my $id = '';

GetOptions (
	'name:s' => \$semestername,  #-u, -user, or -username, fills $username
);

if (!$semestername)
{
  $semestername = prompt ("Semester name: ");
}

my $app = TOME->new();
$id = $app->semester_add({name => $semestername});
$app->semester_set({id => $id});

#print("UserID created is: \"" . $userid . "\", Admin flag is \"" . $admin . "\"\n");

print('Success!' . "\n");
