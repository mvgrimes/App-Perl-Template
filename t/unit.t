use strict;
use warnings;
use Test::More;
use Test::Differences;
use App::Perl::Template;
use Software::License::Perl_5;
use Path::Class;

$ENV{APP_PERL_TEMPLATE_TESTING} = 1;

use File::Temp qw(tempdir);
my $dir = dir( tempdir( CLEANUP => 1 ) );

my $src = Path::Class::File->new('share/templates/lib/NAMESPACE.pm');
my $dst = $dir->file('lib/Dest.pm');

my $file = App::Perl::Template::File->new(
    src_path => $src,
    dst_path => $dst,
    vars     => {
        namespace   => 'Dest',
        author_name => 'The Author',
        email       => 'email@address.com',
        license =>
          Software::License::Perl_5->new( { holder => 'The Author', } ),
    } );

isa_ok( $file, 'App::Perl::Template::File' );
is_deeply(
    $file->_identifiers( scalar $src->slurp ),
    [ '=head1 AUTHOR', '=head1 COPYRIGHT' ],
    'Correct available chunks'
);

my $core = <<'CORE';
=head1 AUTHOR

The Author, E<lt>email@address.comE<gt>

=for perl-template id="=head1 AUTHOR" md5sum=
CORE
chomp $core;
my $chunk = "stuff...\n\n$core\n\nmore stuff\n";

# Test the marker regex:
my $re = $file->marker_regex;
ok( $chunk =~ $re, '... matches' );
is( $+{hash}, '', '... hash is empty' );
is( $+{ident}, '=head1 AUTHOR', '... ident is found' );
is( $+{marker}, 'perl-template id="=head1 AUTHOR" md5sum=',
    '... marker is found' );

# Now break down the chunk processing routines step by step
eq_or_diff( [ $file->_identifiers($chunk) ],
    ['=head1 AUTHOR'], '... found identifiers' );

eq_or_diff(
    $file->_process_chunk( $chunk, '=head1 AUTHOR', sub { 'XXX' } ),
    "stuff...\n\nXXX\n\nmore stuff\n",
    '... processed chunk'
);

eq_or_diff(
    $file->available_chunks($chunk),
    { '=head1 AUTHOR' => $core },
    '... found available chunks'
);

# $chunk = $file->_process_chunks( $chunk, sub {
#                 my ( $self, %h ) = @_;
#                 my $new = $self->_chunk(%h);
#                 return defined $new ? $new : $h{original};
#             });

done_testing;
