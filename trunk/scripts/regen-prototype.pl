#!/usr/bin/perl

use warnings;
use strict;

use HTML::Prototype;

my $prototype = HTML::Prototype->new();

my $genpage = $prototype->define_javascript_functions();

# The previous statement is supposed to be included in an HTML header.  We want it for a static
# file, so strip out the <script> tags.
$genpage =~ s#^\s*<script[^>]*>##;
$genpage =~ s#</script>\s*$##;

$genpage = "<!-- This file is automatically for the TOME system by scripts/regen-prototype.pl -->\n\n" . $genpage;

print $genpage;
