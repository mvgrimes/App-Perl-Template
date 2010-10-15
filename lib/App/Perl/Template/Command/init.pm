package App::Perl::Template::Command::init;

use strict;
use warnings;
use App::Perl::Template -command;

our $VERSION = '0.05';

use File::Spec;
use File::Basename;
use File::Find::Rule;
use File::ShareDir qw(dist_dir);
use File::HomeDir;
use File::Copy qw(copy);
use File::Path qw(mkpath);

sub usage_desc { "init %o" }

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( [ "update|u", "Update previously installed templates" ], );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error(
        "Already initialized. Use --update to recreate the files")
      if $self->already_initialized && !$opt->{update};

    $self->usage_error("No arguments allowed") if @$args;

    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;
    my $result;

    # TODO: make this configurable
    my $ignore_regex = qr{
                (CVS|\.svn|\.git|\.swp)
            $}x;

    my $share_dir = $self->share_dir;
    my $templ_dir = $self->config_dir;;

    my @paths = File::Find::Rule->not_name($ignore_regex)->in($share_dir);
    for my $full_path (@paths) {
        ( my $path = $full_path ) =~ s{$share_dir}{};

        if ( -d $full_path ) {
            my $dir = File::Spec->catdir( $templ_dir, $path );
            mkpath $dir or die "Unable to create dir: $dir\n";
        } else {
            my $file = File::Spec->catdir( $templ_dir, $path );
            copy $full_path, $file
              or die "Unable to copy file: $file\n";
        }

    }
    return 1;
}

sub share_dir {
    my ($self) = @_;

    # If we are in development use that share dir
    my $dir = File::Spec->catfile( dirname( $INC{'App/Perl/Template.pm'} ),
        qw( .. .. .. share ) );

    # Otherwise, use the system share dir
    $dir = dist_dir('App-Perl-Template') unless -d $dir;

    return $dir;
}

1;
