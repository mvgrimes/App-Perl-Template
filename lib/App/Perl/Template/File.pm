package App::Perl::Template::File;

use v5.010;
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

# Would have liked to match chunks with this, but can't use a backreference
# that hasn't yet been matched.
# has chunk_regex => (
#         is => 'ro',
#         isa => 'Regexp',
#         default => sub { qr{
#             (?<original>                     # Capture the entire chunk
#                 \k<ident>                    # Starts with the identifier
#                 (?<body> .*? )               # Then we get the "body"
#                 perl-template \s+            # Finally the marker
#                     "(?<ident>  [^"]* )" \s+ #  including the quoted identifier
#                     md5sum:(?<hash> \w* )    #  and the hash
#             )
#         }xso } );

has marker_regex => (
        is => 'ro',
        isa => 'Regexp',
        default => sub { qr{
            (?<marker>                       # Capture the entire marker
                perl-template \s+            # Starting with the marker text
                    id="(?<ident>  [^"]* )" \s+ #  including the quoted identifier
                    md5sum=(?<hash> \w* )    #  and the hash
            )
        }xso } );

# TODO: this is inconsistent: full file ignores empty lines, chunks don't

method hash($contents) {
    $contents =~ s{\n\s*\n}{\n}mg;             # Strip empty lines
    $contents =~ s{^#\s*perl-template\s+md5sum=(\w*)\s*$}{}m;  # Strip prior file hash
    ## TODO: strip out all whitespace so tidy never causes a problem

    return md5_hex($contents);
}

method create($vars) {
    $self->vars($vars);

    printf "(re)creating:  %s\n", $self->dst_path;
    $self->dst_path->dir->mkpath;
    my $fh = $self->dst_path->openw() or die "Cannot creat file: $!";
    print $fh $self->contents_with_hash;
}

method contents_with_hash {
    # TODO: only insert in acceptable files
    # TODO: change comment marker based on file
    
    my $contents = $self->contents;
    $contents = $self->_process_chunks(
        $contents,
        sub {
            my ( $self, %h ) = @_;
    print "creat md5 = " . md5_hex($h{body}) . "\n";
    print "body = $h{body}\n";
            return
                $h{ident}
              . $h{body}
              . qq{perl-template id="$h{ident}" md5sum=}
              . md5_hex( $h{body} );
        } );

    return $contents . sprintf "# perl-template md5sum=%s\n", $self->hash($contents);
}

method _process_chunk($contents,$identifier,$sub){
    # Have to find the indentifiers first, then match since we can't
    # have a backreference to something matched later in the regex
    
    die "No callback" unless ref $sub eq 'CODE';
    
    # TODO: make sure we aren't spanning perl-template blocks
    $contents =~ s{
            (?<original>                  # Capture the entire chunk
                \Q$identifier\E           # Starting with the identifier
                (?<body> .*? )            # Then we get the "body"
                perl-template \s+         # Finally the marker
                    id="\Q$identifier\E" \s+ #  incld the quoted identifier
                    md5sum=(?<hash> \w* ) #  and the hash
            )
        }{
            # Call the callback w/ %+
            $sub->($self, %+, ident => $identifier)
        }exs;

    return $contents;
}

method _process_chunks($contents,$sub){
    my $possible_chunks = $self->_identifiers( $contents );
    for my $possible_chunk (@$possible_chunks){
        $contents = $self->_process_chunk( $contents, $possible_chunk, $sub );
    }
    return $contents;
}

method _identifiers($contents){
    my $re = $self->marker_regex;
    my $identifiers;
    while( $contents =~ m{$re}g ){
        push @$identifiers, $+{ident};
    }

    return $identifiers;
}

method update($vars) {
    $self->vars($vars);

    # Check for modifications to the file
    my $existing_contents = $self->dst_path->slurp;
    my ($inserted_hash) = $existing_contents =~ m/\bperl-template\s+md5sum=(\w*)/m;
    my $hash = $self->hash($existing_contents);

    if( not $inserted_hash ){
        printf "%s exists and no hash marker found, not updating\n", $self->dst_path;
        return;
    }

    if( $inserted_hash eq $hash ){   # This hasn't been modified, update
        # printf "%s exists and has not been updated, recreating\n", $self->dst_path;
        $self->create( $vars );
        return;
    }

    # File exists and has been modified, check for unmodified chunks:
    printf "%s has been modified, not replacing file\n", $self->dst_path;

    # Chucks are designated by:
    #   perl-template "=head1 AUTHOR" md5sum:
    # which designates the end of a chunk that starts at "=head1 AUTHOR"
    
    # TODO: what about makers in the dst that aren't in the src?

    # Check the chunks:
    $existing_contents =  $self->_process_chunks( $existing_contents, sub {
                    my ( $self, %h ) = @_;
                    my $new = $self->_chunk(%h);
                    return defined $new ? $new : $h{original};
                });

    my $fh = $self->dst_path->openw();
    print $fh $existing_contents;
}

method _chunk( %h ) {
    print "hash = $h{hash}\n";
    print "new md5 = " . md5_hex($h{body}) . "\n";
    print "body = $h{body}\n";

    if ( $h{hash} and $h{hash} ne md5_hex($h{body}) ) {
        printf("not updating chunk $h{ident}...\n");
        return;
    }

    my $chunk = $self->available_chunks_in_src->{$h{ident}};

    if( not defined $chunk ){
        printf "found a chunk (%s) in existing file that isn't in the src\n",
               $h{ident};
        return;
    }

    printf("updating chunk $h{ident}...\n");

    my $new_content = $self->process( $chunk );
    return $self->_process_chunk( $new_content, $h{ident}, sub {
            my ($self,%h) = @_;
            return 
                $h{ident}
              . $h{body}
              . qq{perl-template id="$h{ident}" md5sum=}
              . md5_hex( $h{original} )
            } );

}

method available_chunks_in_src {
    my $content = $self->src_content;
    return $self->available_chunks( $content );
}

method available_chunks($content){
    my %chunks;

    $self->_process_chunks( $content, sub {
            my ($self,%h) = @_;
            $chunks{ $h{ident} } = $h{original};
    } );

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
