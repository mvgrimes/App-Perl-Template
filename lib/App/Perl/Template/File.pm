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

has src_content  => (
    is      => 'ro',
    isa     => 'Str',
    default => method { $self->src_path->slurp },
    lazy    => 1,
);

has template => (
    is      => 'ro',
    isa     => 'Template::Tiny',
    default => sub { Template::Tiny->new } );

method hash($contents) {
    $contents =~ s{\n\s*\n}{\n}mg;             # Strip empty lines
    $contents =~ s{^#\s*md5sum:(\w+)\s*$}{}m;  # Strip prior file hash
    ## TODO: strip out all whitespace so tidy never causes a problem

    return md5_hex($contents);
}

method create($vars) {
    $self->vars($vars);

    printf "processing: %s\n", $self->dst_path;
    $self->dst_path->dir->mkpath;
    my $fh = $self->dst_path->openw() or die "Cannot creat file: $!";
    print $fh $self->contents_with_hash;
}

method contents_with_hash {
    # TODO: only insert in acceptable files
    # TODO: change comment marker based on file
    
    ( my $contents = $self->contents ) =~ s{
        perl-template \s+ md5sum-start \s+ (\w+)
        (.*?)
        perl-template \s+ md5sum:(\w*)
    }{
        "perl-template md5sum-start $1" .
        $2 .
        "perl-template md5sum:" . md5_hex( $2 )
    }xesg;

    return $contents . sprintf "# md5sum:%s\n", $self->hash($contents);
}

method update($vars) {
    $self->vars($vars);

    my $existing_contents = $self->dst_path->slurp;
    my ($inserted_hash) = $existing_contents =~ m/^#\s*md5sum:(\w+)\s*$/m;

    my $hash = $self->hash( $existing_contents );

    if(! $inserted_hash ){
        printf "%s exists and no hash marker found, not updating\n", $self->dst_path;
        return;
    }

    if( $inserted_hash eq $hash ){   # This hasn't been modified, update
        $self->create( $vars );
    } else {
        printf "%s has been modified, not updating\n", $self->dst_path;

        # Check the chunks:
        $existing_contents =~ s{(
            perl-template \s+ md5sum-start \s+ (\w+)
            (.*?)
            perl-template \s+ md5sum:(\w+)
        )}{
            $self->chunk( $1, $2, $3, $4 )
        }xesg;

        # TODO: make sure we aren't getting spanning perl-template blocks

        my $fh = $self->dst_path->openw();
        print $fh $existing_contents;
    }
}

method chunk( $original, $desc, $body, $hash ) {
    my $chunk = $self->available_chunks->{$desc};

    if ( md5_hex($body) eq $hash and $chunk ) {
        printf("updating chunk $desc...\n");

        my $chunk = $self->process($chunk);
        $chunk =~ s{
            perl-template \s+ md5sum-start \s+ (\w+)
            (.*?)
            perl-template \s+ md5sum:(\w*)
        }{
            "perl-template md5sum-start $1" .
            $2 .
            "perl-template md5sum:" . md5_hex( $2 )
        }xesg;

        return $chunk;
    } else {
        printf("not updating chunk $desc...\n");
        return $original;
    }
}

method available_chunks {
    my $content = $self->src_content;

    my @chunks = $content =~ m{(
            perl-template \s+ md5sum-start \s+ 
            .*?
            perl-template \s+ md5sum:\w*
        )}sxg;

    my %chunks = ( map { 
            if (m{perl-template \s+ md5sum-start \s+ (\w+)}x) {
                ( $1 => $_ );
            } else {
                ();
            }
    } @chunks );

    return \%chunks;
}

method contents {
    my $output = '';
    return $self->process( $self->src_content );
}

method process($input) {
    my $output = '';
    $self->template->process( \$input, $self->vars, \$output );
    return $output;
}

1;
