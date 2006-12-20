#Test that the testing framework works correctly

#use lib "../modules"
#use TOME;
use Test::More tests => 2;

#my $app = TOME->new();

#$app->

my $a = 2 + 2;
my $b = 2 * 2;

is ($a, $b);

#Is up down?

is("up", "down");



