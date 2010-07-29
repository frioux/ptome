OpenSiteAdmin Installation Guide

TABLE OF CONTENTS:
    -INSTALL
        -REQUIREMENTS
        -BASIC SETUP
    -DOING SOMETHING USEFUL
        -HOWTO
        -RAQ

INSTALL
-----------------------------
REQUIREMENTS:
PHP >= 5.2
MySQL Database (I think >= 3.x, but I don't know a whole lot about
        databases...)

BASIC SETUP:
1) Set up your database settings in OpenSiteAdmin/include.php
2) Copy OpenSiteAdmin/ and admin/ to some_dir on your website.
3) go to your_website/some_dir/admin/
4) The default login is
        Username: admin
        password: password
5) Change your password (Update My Information)

DOING SOMETHING USEFUL
-----------------------------
HOWTO:
Adding layout styling:
    OpenSiteAdmin looks for two files, header.php and footer.php in the same
    directory the OpenSiteAdmin and admin folders are located. These files are
    included (header first, footer last) to allow for simple integration of the
    administrative console into your existing site layout.

    Modification of filenames or direct layout code insertion should be done in
    OpenSiteAdmin/indexHeader.php and OpenSiteAdmin/indexFooter.php.

Managing More Data:
    To manage more data tables:
        1) Edit admin/index.php, adding an additional call to addPage(foo).
        2) Add a file admin/pages/managefoo.php and insert the contents of
            admin/pages/pageTemplate.tpl
        3) Edit $tableName to be the name of your database table and add/modify
            field definitions as needed, using the commented
            fieldset->addField... as a guide.
        4) See OpenSiteAdmin/scripts/classes/Fields for a list of available
            fields. Field options can also be found prominently in the class
            comment for every field.
    You might also want to check out the existing managers in OpenSiteAdmin/pages/

Extending OpenSiteAdmin:
    OpenSiteAdmin is designed to be highly extensible. If you write new scripts
        or utilities, I recommend you put them in admin/scripts/, But you can
        put them anywhere. You might also consider sharing your extensions with
        the community.

Managing multiple tables/rows from a single page:
    See admin/pages/multiTableTemplate.tpl for an example of how to do this.

RAQ:
Normally, this would be an FAQ, but since no one has asked me any questions, I
will try to anticipate them.

Q: OpenSiteAdmin doesn't support xyz database! Why isn't there a system to
    extend it to support xyz database??
A: I have not had time or need to refactor the code to allow for extending
    database backends. If somebody wants support for a different database
    backend, I will work on the changes necessary to allow that. But other
    people will need to maintain the non MySQL backends.

Q: I noticed your documentation is using phpdoc syntax, but it doesn't
    actually work with phpdoc. Why not?
A: The short answer is that I'm lazy. The long answer is that I've never
    taken the time to figure out how phpdoc works, but I wanted some standard
    way to comment all my code. Feel free to add all the periods and whitespace
    necessary to the comments to make them compliant and submit a patch!

Q: How do code/comment contributions work?
A: Scenario 1 - someone submits a change to existing code.
    If I use their code, their name goes in a comment at the top of the file
    with the date the change was added into the codebase and some way to
    identify where in the code their contribution landed (ie function\method
    name).
   Scenario 2 - someone submits a new file to the codebase.
    A) If they just hand me the code, without any licensing, I will license it
    to them under the Apache 2 license.
    B) If they submit the code anonymously, I will probably GPL it... but it
    might get MIT'd. It kind of depends on how I'm feeling that day.
    C) If they do include licensing information, then of course the code will
    be inserted with the licensing information intact and all future
    modifications will adhere to whatever restrictions from the license apply.

Q: Can I remove the "Powered by OpenSiteAdmin" text?
A: Yes you can! But I can't imagine why you wouldn't want such a decorative
    addition to your site...