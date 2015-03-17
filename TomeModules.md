TOME uses a large collection of Perl modules.  These are all available from CPAN.  Install them using either distro packages, tarballs from http://search.cpan.org/, or using perl -MCPAN -eshell.

This list is probably not complete.  Please add any that were missed, but do try to keep the list clean by omitting any obvious dependencies.  For example, there's no need to list CGI::Session because it is never used outside of CGI::Application::Plugin::Session and will be installed automatically.

Also, note that the apt package libc6-dev is required to build CGI::Application::Plugin::HTMLPrototype and DBD::Pg.  If you don't have it, the packages will fail to compile with a mysterious set of errors.

Also also, DBD::Pg wants the apt package postgresql-devel installed, so it can find pg\_config.

```
Template
Template::Plugin::Comma
Template::Plugin::CGI
CGI::Application
CGI::Application::Plugin::Session
CGI::Application::Plugin::DBH
CGI::Application::Plugin::HTMLPrototype
CGI::Application::Plugin::ValidateRM (needs Compress::Zlib, even though CPAN doesn't show it as a prerequisite)
CGI::Application::Plugin::Forward
DateTime
DateTime::Format::Pg
SQL::Interpolate
MIME::Lite
Crypt::PasswdMD5
DBD::Pg
```

Also note that the install script needs:

```
IO::Prompt
```