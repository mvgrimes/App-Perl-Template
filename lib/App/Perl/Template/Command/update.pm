package App::Perl::Template::Command::update;

use strict;
use warnings;
use App::Perl::Template -command;

use YAML;

# sub usage_desc { "update %o" }

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( [], );
    ## return ( [ "update|u", "Update previously installed templates" ], );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error( "Need to run 'init' before running update")
      unless $self->already_initialized ;

    # TODO: allow .json/META
    $self->usage_error("You must have a MYMETA.yml first") unless -r 'MYMETA.yml';

    my $yaml = YAML::LoadFile( 'MYMETA.yml' ) or die "Error loading MYMETA.yml";
    $self->{config} = { %{ $self->config }, %$yaml };

    $self->usage_error( "Unable to find abstract" )
        unless $self->config->{abstract};
    ( $self->config->{module_name} = $self->config->{name} ) =~ s/-/::/g;
    $self->config->{namespace} = $self->config->{module_name};

    # TODO: find a better way to ensure we are in the root dir of a project
    $self->usage_error("You must 'start' a module first") unless -d 't';
    $self->usage_error("No arguments allowed") if @$args;

    return 1;
}

sub run {
    my ( $self, $opt, $arg ) = @_;
    my $result;

    $self->config->{year} = DateTime->now->year;
    return $self->process_templates( '.' );

    return 1;
}

1;
