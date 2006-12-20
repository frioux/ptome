#!/usr/bin/perl

use strict;
use warnings;

use lib '../modules';

use base 'Interface';

my $app = Interface->new();
$app->run;
