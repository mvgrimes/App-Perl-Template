package App::Perl::Template::Command;

use strict;
use warnings;
use App::Cmd::Setup -command;

our $VERSION = '0.05';

use FindBin;
use File::Copy qw(copy);
use File::HomeDir;
use File::Find::Rule;
use Path::Class;
use App::Perl::Template::File;

use Module::Pluggable
  search_path => 'Software::License',
  require     => 1,
  sub_name    => 'avail_licenses';

sub template_dir {
    my ($self) = @_;
    return $self->config_dir->subdir(qw(templates));
}

sub config_dir {
    my ($self) = @_;
    return dir( $FindBin::Bin, '..', 'share' )
      if $ENV{APP_PERL_TEMPLATE_TESTING};
    return dir( File::HomeDir->my_home, qw(.perl-templates) );
}

sub config_file {
    my ($self) = @_;
    return file( $self->config_dir->file('config') );
}

sub config {
    my ($self) = @_;

    if ( !exists $self->{config} ) {
        $self->{config} =
          { Config::General->new( $self->config_file() )->getall() }
          if -r $self->config_file();
        $self->{config} ||= {};
    }

    return $self->{config};
}

sub module_to_path {
    my ( $self, $module_name ) = @_;
    ( my $dir_name = lc $module_name ) =~ s/::/-/g;
    return $dir_name;
}

sub module_filename {
    my ($self) = @_;

    return $self->module_to_filename( $self->config->{module_name} );
}

sub module_to_filename {
    my ( $self, $name ) = @_;
    $name =~ s{::}{/}g;
    return $name;
}

sub process_templates {
    my ( $self, $dest_dir ) = @_;
    $dest_dir or die "process_templates requires dest-dir";

    $dest_dir = dir($dest_dir);
    my $template_dir = $self->template_dir;

    my @paths = File::Find::Rule->in($template_dir);

    for my $full_path (@paths) {
        ## warn "full path: $full_path\n";

        if ( -d $full_path ) {
            my $path = dir($full_path)->relative($template_dir);
            $path =~ s{NAMESPACE}{$self->module_filename}e;
            ## warn "path: $path\n";
            $self->_mkdir( $dest_dir->subdir($path) );
        } else {
            my $path = file($full_path)->relative($template_dir);
            $path =~ s{NAMESPACE}{$self->module_filename}e;
            ## warn "path: $path\n";
            $self->_copy( file($full_path), $dest_dir->file($path) );
        }

    }
}

sub _mkdir {
    my ( $self, $dir ) = @_;

    return if -d $dir;

    ## warn "mkdir $dir\n";
    ## TODO: process variables
    $dir->mkpath or die "Unable to create dir: $dir\n";
}

sub _copy {
    my ( $self, $src, $dst ) = @_;

    my $file = App::Perl::Template::File->new(
        src_path => $src,
        dst_path => $dst,
    );

    $self->set_license();

    if ( !-e $dst ) {
        $file->create( $self->config );
    } else {
        $file->update( $self->config );
    }
}

sub set_license {
    my ($self) = @_;

    if ( !ref( my $lic = $self->config->{license} ) ) {
        for my $license ( $self->avail_licenses ) {
            if ( $license->meta_name eq $self->config->{license} ) {
                $self->config->{license} =
                  $license->new( { holder => $self->config->{author_name}, } );
                last;
            }
        }
        die "must specify a valid Software::License in the config file ($lic)"
          unless ref $self->config->{license}
              && $self->config->{license}->isa('Software::License');
    }
}

sub already_initialized {
    my ($self) = @_;
    return -d $self->config_dir;
}
1;
