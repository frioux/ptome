# This page is valid only for versions pre 3.0 #

# Shiny Ideals #

## General ##

Read this whole page and understand it.  Really.

use strict;  use warnings;  Always!

Don't reinvent the wheel.  If there's something tricky you need to do, someone has probably already done it.  Check CPAN and ask other developers.

Use K&R style for indentation.  BSD/Allman style is evil.

## admin.pl ##

The only thing this does is load up TOME::Interface and get the party started.

## Interface.pm ##

Implements the TOME::Interface module.  This is to control almost all interaction between the user and TOME.  Nearly every method is a CGI::Application runmode, with the exception of a few helper subs.  Ideally, TOME::Interface shouldn't know any details about the internal database structure or what things look like when they're displayed by the template.

### Coding Guidelines ###

  * Check all user input using CGI::Application::Plugin::ValidateRM (these are the $self->check\_rm calls).

  * Use ValidateRM's nifty features to give good user feedback if something is wrong with their input.  It can nicely refill the form the way it was before and provide error messages.

## TOME.pm ##

Implements the TOME module.  The purpose of this module is to provide database connectivity and all utility functions used by other parts of the program.  Ideally, the TOME module shouldn't know anything about users and especially nothing about templates.

### Coding Guidelines ###

  * Validate all subs with Params::Validate (they're the "validate" calls).  It doesn't matter if you already validated the data in TOME::Interface, do it again.  Sooner or later, someone will make a call with unvalidated data, and catching it is critical.

  * Use SQL::Interpolate (the sql\_interp calls) for all database interaction.  It almost always does the right thing and is nice to look at.  There are a very few instances where a query may be too complex for it to handle, but those are very very rare.  NEVER EVER interpolate variables directy into SQL queries!

  * In most cases, the output from the database should be returned without modification.  However, all dates from the database should be turned into DateTime objects.

## TemplateCallbacks.pm ##

Implements the TOME::TemplateCallbacks module.  All templates are given a "tome" object that is an instantiation of this class.  The idea is that when the template is given ID numbers of various things in the database (patrons, books, tomebooks, etc.) by TOME::Interface, the template can use this object to query the database through the TOME module and get string representations of the data.  This module has the kinda funny place of knowing a little bit about both the template and the database.  Most subs will probably just be wrappers of TOME subs, but if there is any additional data manipulation that needs to take place before the template (without crossing the line of actually doing template work), this is the place to do it.  The reason this is separate from TOME is to give an extra layer of abstraction between the actual database calls and the template.  Giving direct database access from inside a template is a thought too horrible to contemplate.

## Templates ##

All of the template files in the `templates` directory.  These control the actual presentation of data.  As much as possibly, try to keep the templates free of knowledge about the databse or any internals.  Don't abuse the "tome" object to break abstraction.

Put structures that are used commonly in the blocks directory and INCLUDE them in the other templates.  INCLUDE can take a list of locally-scoped variables, which essentially makes the files in blocks like little subroutines.  Current examples include a book.html, which lists all the standard information about a book given an ISBN and datetime.html which converts a DateTime object into the most commonly used format.

## static/prototype.js ##

This file contains all the javascript for those oh-so-cool Web 2.0 thingies like autocompletion.  It is automatically generated from HTML::Prototype by the devdocs/regen-prototype.pl script.  It should be regenerated whenever a new version of HTML::Prototype comes out.

# Depressing Reality #

Unfortunately, nothing is perfect.  TOME development started in the winter of 2003 and has seen steady work ever since.  During this time, several development and abstraction ideas were tried until arriving at the current model.  There are still plenty of bad examples hanging around, so don't always trust looking at old code for a good example.  When in doubt about how to implement something without breaking abstraction, ask another developer who has more experience!

The Patron information page is currently the only code path that follows these new guidelines.  It is a good place to look for examples.