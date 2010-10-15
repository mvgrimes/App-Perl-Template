package App::Perl::Template::Command::start;

use strict;
use warnings;
use App::Perl::Template -command;

our $VERSION = '0.05';

use DateTime;

sub usage_desc { "start Module::Name" }

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( [ "abstract|a=s", "Abstract for the new module" ], );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error("Need to run 'init' before running start")
      unless $self->already_initialized;

    $self->usage_error("Module::Name required") unless @$args;

    my $module_name = shift @$args;
    $self->usage_error("Only one Module::Name may be supplied") if @$args;

    my $dir_name = $self->module_to_path($module_name);
    $self->usage_error("Module directory ($dir_name) already exists")
      if -d $dir_name;

    $self->usage_error("Abstract required") unless $opt->{abstract};

    $self->config->{namespace} = $self->config->{module_name} = $module_name;
    $self->config->{dir_name}  = $dir_name;
    $self->config->{abstract}  = $opt->{abstract};
    $self->config->{year}      = DateTime->now->year;

    return 1;
}


sub execute {
    my ( $self, $opt, $arg ) = @_;
    my $result;

    return $self->process_templates( $self->config->{dir_name} );

    return 1;
}

1;
