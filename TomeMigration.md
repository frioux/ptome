# Steps #
  * Code
    * Branch repository "svn copy trunk branches/release-2"
    * Lock apache with .htaccess "Deny from all" in public\_html
    * Move ptome to ptome-old in ~/projects/
    * Backup database "backup-tomedb-hourly.sh"
    * Checkout branch "branches/release-2"
    * Copy ptome-old/site-config.pl to ptome/site-config.pl to copy old site configuration to new ptome
    * _Code is now completely migrated_
  * Migrations
    * Run migration scripts