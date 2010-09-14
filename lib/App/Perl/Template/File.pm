package App::Perl::Template::File;

use Mouse;
use Method::Signatures::Simple;
use Path::Class;
use Template::Tiny;
use Digest::MD5 qw(md5_hex);

our $VERSION = '0.03';

has src_path => ( is => 'ro', isa => 'Path::Class::File', required => 1 );
has dst_path => ( is => 'ro', isa => 'Path::Class::File', required => 1 );
has vars     => ( is => 'rw', isa => 'HashRef' );

has original_contents => (
    is      => 'ro',
    isa     => 'Str',
    default => method { $self->src_path->slurp },
    lazy    => 1,
);

has template => (
    is      => 'ro',
    isa     => 'Template::Tiny',
    default => sub { Template::Tiny->new } );

method hash {
    ( my $no_empty_lines = $self->contents ) =~ s{\n\s*\n}{\n}mg;
    # TODO: strip out all whitespace so tidy never causes a problem
    return md5_hex($no_empty_lines);
}

method create($vars) {
    $self->vars($vars);

    printf "creating: %s\n", $self->dst_path;
    $self->dst_path->dir->mkpath;
    my $fh = $self->dst_path->openw() or die "Cannot creat file: $!";
    print $fh $self->contents_with_hash;
}

method contents_with_hash {
    # TODO: only insert in acceptable files
    # TODO: change comment marker based on file
    return $self->contents . sprintf "# md5sum:%s\n", $self->hash;
}

method update($vars) {
    my $existing_contents = $self->dst_path->slurp;
    $existing_contents =~ s/^#\s*md5sum:(\w+)\s*$//m;
    my $inserted_hash = $1;
    $existing_contents =~ s{\n\s*\n}{\n}mg;
    my $hash = md5_hex $existing_contents;

    if(! $inserted_hash ){
        printf "%s exists and no hash marker found, not updating\n", $self->dst_path;
        return;
    }

    if( $inserted_hash eq $hash ){   # This hasn't been modified, update
        $self->create( $vars );
    } else {
        printf "%s has been modified, not updating\n", $self->dst_path;
    }
}

method contents {
    my $output = '';

    my $input = $self->original_contents;
    $self->template->process( \$input, $self->vars, \$output );
    return $output;
}

1;
