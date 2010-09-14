package App::Perl::Template::Command::start;

use strict;
use warnings;
use App::Perl::Template -command;
use DateTime;

sub usage_desc { "start Module::Name" }

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( [] );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error("Need to run 'init' before running start")
      unless $self->already_initialized;

    $self->usage_error("no options yet") if keys %$opt;
    $self->usage_error("Module::Name required") unless @$args;

    my $module_name = shift @$args;
    $self->usage_error("Only one Module::Name may be supplied") if @$args;
    $self->config->{namespace} = $self->config->{module_name} = $module_name;

    my $dir_name = $self->module_to_path($module_name);
    $self->usage_error("Module directory ($dir_name) already exists")
      if -d $dir_name;
    $self->config->{dir_name} = $dir_name;

    return 1;
}

sub run {
    my ( $self, $opt, $arg ) = @_;
    my $result;

    $self->config->{abstract} = prompt_str("Enter an Abstract");
    $self->config->{year}     = DateTime->now->year;

    return $self->process_templates( $self->config->{dir_name} );

    return 1;
}

1;
