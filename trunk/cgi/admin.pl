#!/usr/bin/perl -T

use strict;
use warnings;

use lib '../modules';

use TOME::Interface;

my $app = TOME::Interface->new();
$app->run;
