package App::Perl::Template::Command;

use strict;
use warnings;

use File::Spec;
use File::Copy qw(copy);
use File::HomeDir;
use File::Find::Rule;
use File::Slurp;
use Template::Tiny;
use Digest::MD5 qw(md5_base64);

use App::Cmd::Setup -command;

sub template_dir {
    my ($self) = @_;

    return File::Spec->catdir( File::HomeDir->my_home, qw(.perl-templates) );
}

sub _rc_file {
    return File::Spec->catfile( File::HomeDir->my_home,
        qw(.perl-templates config) );
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
    my $dest_dir = $args{dest_dir} || die "process_templates requires dest-dir";
    my $template_dirs = $args{template_dirs}
      || die "process_templates requires template_dirs";

    my $the_template_dir =
      File::Spec->catdir( $self->template_dir, 'templates' );

    for my $template_dir (@$template_dirs) {
        my $full_template_dir =
          File::Spec->catdir( $the_template_dir, $template_dir );

        warn "processing: $full_template_dir\n";

        my @paths = File::Find::Rule->in($full_template_dir);
        for my $full_path (@paths) {
            warn "full path: $full_path\n";
            ( my $path = $full_path ) =~ s{$the_template_dir}{};
            warn "path: $path\n";

            if ( -d $full_path ) {
                $self->_mkdir( File::Spec->catdir( $dest_dir, $path ) );
            } else {
                $self->_copy( $full_path,
                    File::Spec->catdir( $dest_dir, $path ) );
            }

        }
    }
}

sub _mkdir {
    my ( $self, $dir ) = @_;

    return if -d $dir;

    warn "mkdir $dir\n";
    ## TODO: process variables
    mkdir $dir or die "Unable to create dir: $dir\n";
}

sub _copy {
    my ( $self, $src, $dst ) = @_;

    if ( !-e $dst ) {
        $self->_get_file( $src );
    } else {
        copy( $src, $dst ) or die;
        # $self->_process( $src->{contents}, $dst );
    }
}

sub _get_file {
    my ( $self, $file ) = @_;

    my $contents = file_read($src) or die;
    ( my $no_empty_lines = $conents ) =~ s{^\*$}{};
    my $md5 = md5_base64($no_empty_lines);

    return {
        filename => $file,
        contents => $contents,
        md5      => $md5,
    };
}

# sub _process {
#     my ($self,$file) = @_;
# 
#     my $output = '';
#     $template->process( \$input, $vars, \$output );
# 
#     return $output;
# }

1;
