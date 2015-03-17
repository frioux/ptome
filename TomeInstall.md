Prerequisites: Apache, PostgreSQL, Perl, TomeModules

Note: If you are going to set things up the way that this guide suggests, you need to allow symlinks in you apache configuration.

First, you'll need a copy of TOME out of version control.  See the "Source" tab above for information on how to do that.

Assuming the target filesystem layout is similar to Debian, the recommended path to check the repository out to is /usr/local/webapps/tome-dev.  Then, put a symlink from /usr/lib/cgi-bin/tome to /usr/local/webapps/tome-dev/cgi and from /var/www/tome to /usr/local/webapps/tome-dev/static.
```
ln -s /usr/lib/cgi-bin/tome /usr/local/webapps/tome-dev/cgi
ln -s /var/www/tome /usr/local/webapps/tome-dev/static
```

A file called site-config.pl that defines a %CONFIG hash similar to the one in TOME.pm needs to be created in the root directory of your checkout.  This file will never be checked into subversion because it contains all of the settings specific to that install.  Here's an example, so you don't have to find it in TOME.pm:

```
our %CONFIG = (
	cgibase		=> '/perl/tome/cgi',
	staticbase	=> '/tome',

	templatepath	=> '/usr/local/webapps/tome-dev/templates',

	dbidbname	=> 'tome',
	dbihostname	=> 'localhost',
	dbiport		=> '5432',
	dbiusername	=> 'tome',
	dbipassword	=> 'password',

	notifyfrom	=> 'TOMEkeeper <tomekeeper@tome>',
	adminemail	=> 'TOMEadmin <tomeadmin@tome>',

	devmode		=> 1,
	devemailto	=> 'TOMEadmin <tomeadmin@tome>',
);
```

You'll need to create a PostgreSQL database and user that matches what was specified in the config.  Contact another developer for a dump of a database to import.

## Setting Up PostgreSQL ##
These instructions should work for Debian/Ubuntu.  Run all of these commands as the postgres user (become root, then do `su postgres`).  This command creates a user called `tome` with a password.
```
$ createuser --pwprompt
Enter name of role to add: tome
Enter password for new role:
Enter it again:
Shall the new role be a superuser? (y/n) n
Shall the new role be allowed to create databases? (y/n) n
Shall the new role be allowed to create more new roles? (y/n) n
```
This next command creates a database called `tome` that is owned by the `tome` user.
```
$ createdb -O tome tome
```

Assuming you have a dump of a current database called `tomedb`, the following command will import it.
```
zcat tomedb | psql tome
```