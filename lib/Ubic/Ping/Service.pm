package Ubic::Ping::Service;

use strict;
use warnings;

use Ubic::Service::Common;
use Ubic::Daemon qw(:all);
use Ubic::Result qw(result);
use LWP::Simple;
use POSIX;
use Time::HiRes qw(sleep);

use Config;

# ugly; waiting for druxa's Mopheus to save us all...
my $port = $ENV{UBIC_SERVICE_PING_PORT} || 12345;
my $pidfile = $ENV{UBIC_SERVICE_PING_PID} || "/var/lib/ubic/ubic-ping.pid";
my $user = $ENV{UBIC_SERVICE_PING_USER} || 'root';
my $log = $ENV{UBIC_SERVICE_PING_LOG} || '/dev/null';

my $perl = $Config{perlpath};

sub new {
    Ubic::Service::Common->new({
        start => sub {
            my $pid;
            start_daemon({
                bin => qq{$perl -MUbic::Ping -e 'Ubic::Ping->new($port)->run;'},
                name => 'ubic-ping',
                pidfile => $pidfile,
                stdout => $log,
                stderr => $log,
                ubic_log => $log,
            });
        },
        stop => sub {
            stop_daemon($pidfile);
        },
        status => sub {
            my $daemon = check_daemon($pidfile);
            unless ($daemon) {
                return 'not running';
            }
            my $result = get("http://localhost:$port/ping") || '';
            return ((
                $result =~ /^ok$/
            ) ? result('running', "pid ".$daemon->pid) : result('broken'));
        },
        port => $port,
        user => $user,
        timeout_options => { start => { step => 0.1, trials => 3 }},
    });
}

1;