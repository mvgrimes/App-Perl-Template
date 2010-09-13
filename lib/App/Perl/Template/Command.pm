package App::Perl::Template::Command;

use strict;
use warnings;

use File::Copy qw(copy);
use File::HomeDir;
use File::Find::Rule;
use Path::Class;
use App::Perl::Template::File;

use App::Cmd::Setup -command;

sub template_dir {
    my ($self) = @_;

    return dir( File::HomeDir->my_home, qw(.perl-templates) );
}

sub _rc_file {
    return file( File::HomeDir->my_home, qw(.perl-templates config) );
}

sub config {
    my $app = shift;

    if ( !exists $app->{config} ) {
        $app->{config} = { Config::General->new( _rc_file() )->getall() }
          if -r _rc_file();
        $app->{config} ||= {};
    }

    return $app->{config};
}

sub model_to_path {
    my ( $self, $module_name ) = @_;
    ( my $dir_name = lc $module_name ) =~ s/::/-/g;
    return $dir_name;
}

sub process_templates {
    my ( $self, %args ) = @_;
    $args{dest_dir}      || die "process_templates requires dest-dir";
    $args{template_dirs} || die "process_templates requires template_dirs";

    my $dest_dir         = dir( $args{dest_dir} );
    my $template_dirs    = $args{template_dirs};
    my $the_template_dir = $self->template_dir->subdir('templates');

    for my $template_dir ( map { dir($_) } @$template_dirs ) {
        my $full_template_dir = $the_template_dir->subdir($template_dir);
        warn "processing: $full_template_dir\n";

        my @paths = File::Find::Rule->in($full_template_dir);

        for my $full_path (@paths) {

            warn "full path: $full_path\n";

            if ( -d $full_path ) {
                my $path = dir($full_path)->relative($the_template_dir);
                warn "path: $path\n";
                $self->_mkdir( $dest_dir->subdir($path) );
            } else {
                my $path = file($full_path)->relative($the_template_dir);
                warn "path: $path\n";
                $self->_copy( file($full_path), $dest_dir->file($path) );
            }

        }
    }
}

sub _mkdir {
    my ( $self, $dir ) = @_;

    return if -d $dir;

    warn "mkdir $dir\n";
    ## TODO: process variables
    $dir->mkpath or die "Unable to create dir: $dir\n";
}

sub _copy {
    my ( $self, $src, $dst ) = @_;

    my $file = App::Perl::Template::File->new(
        src_path => $src,
        dst_path => $dst,
    );

    if ( !-e $dst ) {
        copy( $src, $dst ) or die;
        $file->create( $self->config );
    } else {
        warn "Already exists: $dst\n";
        $file->updated( $self->config );
    }
}

1;
