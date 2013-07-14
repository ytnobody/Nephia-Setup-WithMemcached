package Nephia::Setup::WithMemcached;
use 5.008005;
use strict;
use warnings;
use File::Spec;

our $VERSION = "0.01";

sub required_modules {
    (
        'Proclet'                 => '0',
        'Plack::Handler::Starlet' => '0',
        'File::Which'             => '0',
    );
};

sub additional_methods {
    qw/create_proclet_runfile/;
};

sub create_proclet_runfile {
    my $setup = shift;
    my $runfile = File::Spec->catfile( $setup->approot, 'run.pl' );
    $setup->spew($runfile, $setup->templates->{proclet_runfile} );
    chmod 0755, $runfile;
}

1;
__DATA__
proclet_runfile
---
#!/usr/bin/env perl
use strict;
use Proclet;
use Plack::Loader;
use Plack::Util;
use File::Spec;
use File::Basename qw(dirname);
use File::Which;

my $proclet = Proclet->new( color => 1 );

### webapp
{
    my $worker_setting = {
        port        => 5000,        # port for listening
        host        => '0.0.0.0',   # bind-addr for listening
        max_workers => 8,           # number for max workers
    };
    my $psgi_file = File::Spec->catfile( dirname(__FILE__), 'app.psgi' );
    my $app       = Plack::Util::load_psgi($psgi_file);
    $proclet->service(
        code => sub {
            local $0 = "$0 [webapp]";
            my $loader = Plack::Loader->load(
                Starlet => ( %$worker_setting )
            );
            $loader->run($app);
        },
        tag  => 'webapp',
    );
}

### memcached
{
    my $worker_setting = {
        '-p'        => '11211',     # port for listening (TCP)
        '-U'        => '11211',     # port for listening (UDP). 0 to off
        '-l'        => '0.0.0.0',   # bind-addr for listening
        '-m'        => '256',       # max allocation memory size (MB)
        '-t'        => '4',         # number of threads to use (default: 4)
    };
    $proclet->service(
        code => sub {
            exec(which('memcached'), %$worker_setting);
        },
        tag  => 'memcached',
    );
}

# run applications
$proclet->run;

===


__END__

=encoding utf-8

=head1 NAME

Nephia::Setup::WithMemcached - Setup flavor for creating nephia application that uses memcached

=head1 SYNOPSIS

    nephia-setup YourApp --flavor WithMemcached
    cd ./YourApp
    ./run.sh

=head1 DESCRIPTION

This module creates bootup-script(run.pl) with Proclet.

=head1 LICENSE

Copyright (C) ytnobody / satoshi azuma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody / satoshi azuma E<lt>ytnobody@gmail.comE<gt>

=cut

