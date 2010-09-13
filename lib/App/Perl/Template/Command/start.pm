package App::Perl::Template::Command::start;

use strict;
use warnings;
use App::Perl::Template -command;

sub usage_desc { "start Module::Name" }

sub opt_spec {
    my ($class,$app) =@_;
    return ( [] );
    #     [ "start_location|s=s", "The line,column of the start" ],
    #     [ "end_location|e=s",   "The line,column of the end" ],
    #     [ "varname|v=s",        "The new variable name" ],
    # );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    # TODO: ensure initialized
    
    $self->usage_error("no options yet") if keys %$opt;
    $self->usage_error("Module::Name required") unless @$args;

    my $module_name = shift @$args;
    $self->usage_error("Only one Module::Name may be supplied") if @$args;
    $self->config->{module_name} = $module_name;

    my $dir_name = $self->model_to_path( $module_name);
    $self->usage_error("Module directory ($dir_name) already exists")
        if -d $dir_name;
    $self->config->{dir_name} = $dir_name;

    return 1;
}

sub run {
    my ( $self, $opt, $arg ) = @_;
    my $result;

    $self->config->{abstract} = 'the abstract';
    $self->config->{namespace} = 'the namespace';

    return $self->process_templates(
        dest_dir      => $self->config->{dir_name},
        template_dirs => ['.'],
    );

    return 1;
}

1;
