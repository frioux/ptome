So you accidentally hosed tome while you were trying to run a migration?  Fortunately our server does backups hourly with cron.  To restore from any one of these backups (tomedb-hourly should be the newest) you should use zcat, which will gunzip it on the fly.

So the basic command will be something like this:

zcat tomedb-hourly | psql

You will probably need to add user data