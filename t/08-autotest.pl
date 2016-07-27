#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Output;
use Test::Fatal;
use Test::MockModule;

BEGIN {
    unshift @INC, '..';
}

use autotest;
use bmwqemu;
$bmwqemu::vars{CASEDIR} = 't/fake';

like(exception { autotest::runalltests}, qr/ERROR: no tests loaded/, 'runalltests needs tests loaded first');
stderr_like(
    sub { like(exception {autotest::loadtest 'does/not/match'}, qr/loadtest needs a script to match/) },
    qr/loadtest needs a script below.*is not/);

sub loadtest {
    my ($test, $args) = @_;
stderr_like( sub { autotest::loadtest "tests/$test.pm" }, qr@scheduling $test tests/$test.pm@, \$args);
}

loadtest 'start';
loadtest 'next';
is(keys %autotest::tests, 2);
loadtest 'start', 'rescheduling same step later is accepted but does overwrite existing step';
is(keys %autotest::tests, 2, 'previous start step is overwritten');

my $mock_jsonrpc = new Test::MockModule('myjsonrpc');
$mock_jsonrpc->mock(send_json => sub {});
$mock_jsonrpc->mock(read_json => sub {});
my $mock_bmwqemu = new Test::MockModule('bmwqemu');
$mock_bmwqemu->mock(save_json_file => sub {});
my $mock_basetest = new Test::MockModule('basetest');
$mock_basetest->mock(_result_add_screenshot => sub {});

ok(autotest::runalltests);

done_testing();

# vim: set sw=4 et:
