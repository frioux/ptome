#!/usr/bin/perl

use strict;
use warnings;

use lib "../modules";
#use TOME;
use Crypt::PasswdMD5;
use IO::Prompt;
use DBI;
use IO::File;

my $serveraddress = '';
my $serverport = '';
my $supername = '';
my $superpass = '';
my $username = '';
my $userpass = '';
my $database = '';
my @args = '';
my $siteconfig = '';
my $configfile = '';
my $confighandle = '';
my $FH = '';
my $tomeuser = '';
my $tomepass = '';
my $tomeemail = '';
my $semestername = '';


print ("Welcome to the TOME installer!\n");
print ("This script will set up the database and configuration files that TOME needs.  \n");
print ("\n");

print ("Checking to make sure the installer has root privileges...\n");

if ($> != 0) {
	die "\nYou must run the installer as root!\n";
}

#This will be operational only if we get rid of the need for installing plpgsql into the database
#print ("First, do you wish to create a new database or use an existing one?\n");
#prompt (-menu => ['Create a new database', 'Use an existing one']);
#print ("You chose " . $_ . "\n");
#print ("\n");

#For now we assume they chose 'Create a new database'
print ("To create the TOME database, the connection details of a PostgreSQL superuser will be required.\n");
$supername = prompt ("Username: ", -default => 'postgres');
#$superpass = prompt ("Password: ", -echo => '');

print ("\n");
print ("What username would you like the TOME database to use?\n");
print ("If the username already exists, you may see an error message to that effect.  Feel free to ignore it.\n");
$username = prompt ("Username: ", -default => 'tome');
print ("Attempting to create user \'" . $username . "\'...\n");

@args = ("su", "postgres", "-c", "createuser $username -SDRP");
system (@args);

print ("\n");
print ("What database do you want TOME to use?  For now, please enter a new database name, as the install script doesn't check to see if it's there beforehand.\n");
$database = prompt ("Database name: ", -default => 'tome');
print ("Attempting to create database \'" . $database . "\'...\n");

@args = ("su", "postgres", "-c", "createdb -O $username -T template0 $database");
system (@args);

print ("Installing the plpgsql language on database \'" . $database . "\'...\n");

@args = ("su", "postgres", "-c", "createlang plpgsql $database");
system (@args);

print ("Inserting the TOME schema into the database...\n");

@args = ("su", "postgres", "-c", "psql $database $username -h 127.0.0.1 -f ../devdocs/schema.sql");
system (@args);

print ("\n");
print ("Now that the database has been created, we need to initialize the site-config.pl file.  ");
print ("The next series of questions will fill in the information necessary to produce a working config file.  ");
print ("At this point, you'll have to make the necessary symlinks yourself, due to their distro-dependant nature.\n");

$siteconfig .= 'our %CONFIG = (' . "\n";

print ("\n");
print ("What should the CGI base directory be?\n");
prompt ("cgibase: ", -default => '/cgi-bin/tome');

$siteconfig .= '    cgibase        => \'' . $_ . '\',' . "\n";

print ("\n");
print ("What should the static base directory be?\n");
prompt ("staticbase: ", -default => '/tome');

$siteconfig .= '    staticbase     => \'' . $_ . '\',' . "\n";
$siteconfig .= "\n";

print ("\n");
print ("What should the template path be?\n");
print ("(Eventually, this should check the current working directory and set the default from there.  Right now, it's hardcoded.)\n");
prompt ("templatepath: ", -default => '/usr/local/webapps/tome-dev/templates');

$siteconfig .= '    templatepath   => \'' . $_ . '\',' . "\n";
$siteconfig .= "\n";

print ("\n");
print ("What database name should TOME connect to?\n");
print ("(This defaults to the database you created earlier)\n");
prompt ("dbidbname: ", -default => $database);

$siteconfig .= '    dbidbname   => \'' . $_ . '\',' . "\n";

print ("\n");
print ("What is the address of the database server TOME will be connecting to?\n");
prompt ("dbihostname: ", -default => '127.0.0.1');

$siteconfig .= '    dbihostname => \'' . $_ . '\',' . "\n";

print ("\n");
print ("What port should TOME connect on?\n");
prompt ("dbiport: ", -default => '5432');

$siteconfig .= '    dbiport     => \'' . $_ . '\',' . "\n";

print ("\n");
print ("What username should TOME use to connect?\n");
prompt ("dbiusername: ", -default => $username);

$siteconfig .= '    dbiusername    => \'' . $_ . '\',' . "\n";

print ("\n");
print ("What password should TOME use to connect?\n");
prompt ("dbipassword: ", -echo => '');

$siteconfig .= '    dbipassword    => \'' . $_ . '\',' . "\n";
$siteconfig .= "\n";

print ("\n");
print ("Where should notify emails appear to come from?\n");
prompt ("notifyfrom: ", -default => 'TOMEkeeper <tomekeeper@tome>');

$siteconfig .= '    notifyfrom     => \'' . $_ . '\',' . "\n";

print ("\n");
print ("What should the admin email address be?\n");
prompt ("adminemail: ", -default => 'TOMEadmin <tomeadmin@tome>');

$siteconfig .= '    adminemail     => \'' . $_ . '\',' . "\n";
$siteconfig .= "\n";

print ("\n");
print ("Should the development flag be set?\n");
print ("(1 is on, 0 is off)\n");
prompt ("devmod: ", -default => '1');

$siteconfig .= '    devmode        => \'' . $_ . '\',' . "\n";

print ("\n");
print ("Where should development email go to?\n");
prompt ("devemailto: ", -default => 'TOMEadmin <tomeadmin@tome>');

$siteconfig .= '    devemailto     => \'' . $_ . '\',' . "\n";
$siteconfig .= ');' . "\n";

print ("\n");
print ("Attempting to write site-config.pl...\n");

if (-e "../site-config.pl") {
	if (prompt ("site-config.pl already exists!  Do you wish to overwrite it? ", -yn)) {
		if (open (FH, ">", '../site-config.pl')) {
			print FH $siteconfig;
			close (FH);
		} else {
			print ("Can\'t open site-config.pl for writing!\n");
			print ("Here\'s what would have been written:\n");
			print ("\n");
			print ($siteconfig . "\n");
		}
	} else {
		print ("Here's what would have been written:\n");
		print ("\n");
		print ($siteconfig . "\n");
	}
} else {
	if (open (FH, ">", '../site-config.pl')) {
		print FH $siteconfig;
		close (FH);
	} else {
		print ("Can\'t open site-config.pl for writing!\n");
		print ("Here\'s what would have been written:\n");
		print ("\n");
		print ($siteconfig . "\n");
	}
}

print ("\n");
print ("Now the program will attempt to create an admin user on TOME.\n");
print ("What would you like the username, password, and registered email address to be?\n");
$tomeuser = prompt ("Username: ", -default => 'admin');
$tomepass = prompt ("Password: ", -echo => '');
$tomeemail = prompt ("Email: ", -default => 'admin@tome');

@args = ('./createuser.pl', '-u', $tomeuser, '-p', $tomepass, '-e', $tomeemail, '-admin');
system (@args);

print ("\n");
print ("Finally, we need to add a default semester.\n");
print ("What would you like the name of the new semester to be?\n");
$semestername = prompt ("Semester name: ", -default => 'Fall 06');

@args = ('./createsemester.pl', '-name', $semestername);
system (@args);
