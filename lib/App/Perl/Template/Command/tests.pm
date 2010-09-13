package App::Perl::Template::Command::tests;

use strict;
use warnings;
use App::Perl::Template -command;

sub usage_desc { "tests %o" }

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( [], );

    # return ( [ "update|u", "Update previously installed templates" ], );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error("You must 'start' a module first") unless -d 't';
    $self->usage_error("No arguments allowed") if @$args;

    return 1;
}

sub run {
    my ( $self, $opt, $arg ) = @_;
    my $result;

    $self->process_templates(
        dest_dir      => '.',
        template_dirs => [qw( t xt )],
    );

    return 1;
}

1;
