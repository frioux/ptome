#Test that the testing framework works correctly

use lib "../modules"
use TOME;
use Test::More tests => 2;

my $app = TOME->new();

$app->

#Is up down?

is("up", "down");



