# This is an example site-config.pl.  Please modify it to match your local
# configuration.  Documentation on each of these values can be found in the
# POD of the TOME module.

our %CONFIG = (
	cgibase		=> '/perl/tome/cgi',
	staticbase	=> '/tome',

	templatepath	=> '../templates',

	dbidbname	=> 'tome',
	dbihostname	=> 'localhost',
	dbiport		=> '5432',
	dbiusername	=> 'tome',
	dbipassword	=> 'password',

	notifyfrom	=> 'TOMEkeeper <tomekeeper@tome>',
	adminemail	=> 'TOMEadmin <tomeadmin@tome>',

	devmode		=> 0,
	devemailto	=> 'TOMEadmin <tomeadmin@tome>',
);
